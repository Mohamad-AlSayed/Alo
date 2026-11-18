#!/usr/bin/env bash
set -euo pipefail

DOMAIN="alo.ms.sy"
REPO_URL="https://github.com/Mohamad-AlSayed/Alo.git"
APP_DIR="/opt/alo"

echo "== 1/7: System packages =="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg git ufw

echo "== 2/7: Docker =="
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
fi

echo "== 3/7: Firewall =="
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 7880:7881/tcp
sudo ufw allow 50000:60000/udp
sudo ufw --force enable

echo "== 4/7: Clone app repo =="
if [ -d "$APP_DIR" ]; then
  sudo git -C "$APP_DIR" pull
else
  sudo git clone --depth 1 "$REPO_URL" "$APP_DIR"
fi
sudo chown -R "$USER":"$USER" "$APP_DIR"

echo "== 5/7: Supabase (self-hosted) =="
if [ ! -d "$APP_DIR/supabase-project" ]; then
  git clone --depth 1 https://github.com/supabase/supabase "$APP_DIR/supabase-src"
  cp -r "$APP_DIR/supabase-src/docker" "$APP_DIR/supabase-project"
  rm -rf "$APP_DIR/supabase-src"
  cp "$APP_DIR/supabase-project/.env.example" "$APP_DIR/supabase-project/.env"
  # generate strong secrets
  JWT_SECRET=$(openssl rand -hex 32)
  POSTGRES_PASSWORD=$(openssl rand -hex 16)

  b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
  make_jwt() {
    local role="$1"
    local header payload sig
    header=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
    payload=$(printf '{"role":"%s","iss":"supabase","iat":%d,"exp":%d}' "$role" "$(date +%s)" "$(( $(date +%s) + 157680000 ))" | b64url)
    sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | b64url)
    printf '%s.%s.%s' "$header" "$payload" "$sig"
  }
  ANON_KEY=$(make_jwt anon)
  SERVICE_ROLE_KEY=$(make_jwt service_role)

  sed -i "s#^POSTGRES_PASSWORD=.*#POSTGRES_PASSWORD=${POSTGRES_PASSWORD}#" "$APP_DIR/supabase-project/.env"
  sed -i "s#^JWT_SECRET=.*#JWT_SECRET=${JWT_SECRET}#" "$APP_DIR/supabase-project/.env"
  sed -i "s#^ANON_KEY=.*#ANON_KEY=${ANON_KEY}#" "$APP_DIR/supabase-project/.env"
  sed -i "s#^SERVICE_ROLE_KEY=.*#SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}#" "$APP_DIR/supabase-project/.env"
  sed -i "s#^SITE_URL=.*#SITE_URL=https://${DOMAIN}#" "$APP_DIR/supabase-project/.env"
  sed -i "s#^API_EXTERNAL_URL=.*#API_EXTERNAL_URL=https://${DOMAIN}/api#" "$APP_DIR/supabase-project/.env"
  # No SMTP configured yet: auto-confirm email signups so login works immediately.
  # Once real SMTP is set up, change this back to false.
  if grep -q '^ENABLE_EMAIL_AUTOCONFIRM=' "$APP_DIR/supabase-project/.env"; then
    sed -i "s#^ENABLE_EMAIL_AUTOCONFIRM=.*#ENABLE_EMAIL_AUTOCONFIRM=true#" "$APP_DIR/supabase-project/.env"
  else
    echo "ENABLE_EMAIL_AUTOCONFIRM=true" >> "$APP_DIR/supabase-project/.env"
  fi

  mkdir -p "$APP_DIR/secrets"
  cat > "$APP_DIR/secrets/supabase_keys.txt" <<EOF2
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
JWT_SECRET=${JWT_SECRET}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF2
  echo ">> المفاتيح محفوظة أيضاً بـ: $APP_DIR/secrets/supabase_keys.txt"
fi

echo "== 6/7: LiveKit (self-hosted) =="
mkdir -p "$APP_DIR/livekit"
if [ ! -f "$APP_DIR/livekit/livekit.yaml" ]; then
  LIVEKIT_KEY=$(openssl rand -hex 16)
  LIVEKIT_SECRET=$(openssl rand -hex 32)
  cat > "$APP_DIR/livekit/livekit.yaml" <<EOF
port: 7880
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
keys:
  ${LIVEKIT_KEY}: ${LIVEKIT_SECRET}
EOF
  echo ">> LiveKit API Key: ${LIVEKIT_KEY}"
  echo ">> LiveKit API Secret: ${LIVEKIT_SECRET}"
  echo ">> Save these — needed in web/.env.local as LIVEKIT_API_KEY / LIVEKIT_API_SECRET"
fi

cat > "$APP_DIR/docker-compose.override.yml" <<'EOF'
services:
  livekit:
    image: livekit/livekit-server:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./livekit/livekit.yaml:/etc/livekit.yaml
    command: --config /etc/livekit.yaml
EOF

echo "== 7/7: Done. Next steps printed below =="
cat <<EOF

التجهيز الأساسي خلص. المفاتيح تولّدت تلقائياً وموجودة بـ:
  $APP_DIR/secrets/supabase_keys.txt

الخطوات المتبقية:

1. شغّل Supabase:
   cd $APP_DIR/supabase-project && docker compose up -d

2. شغّل LiveKit:
   cd $APP_DIR && docker compose -f docker-compose.override.yml up -d

ملاحظة: LiveKit ما بيحتاج بورت عام مفتوح للـsignaling — هيك عم نعمل reverse-proxy له عبر Nginx بالخطوة الجاية (نفس الدومين، بورت 443). بس بورتات UDP (50000-60000) والـTCP (7881) بالفايروول ضروريين لوسائط المكالمات مباشرة.

3. شغّل سكريبت الويب + SSL:
   bash $APP_DIR/deploy/web_and_tls.sh
EOF
