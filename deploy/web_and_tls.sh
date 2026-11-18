#!/usr/bin/env bash
set -euo pipefail

DOMAIN="alo.ms.sy"
APP_DIR="/opt/alo"
EMAIL="${CERTBOT_EMAIL:?set CERTBOT_EMAIL env var to your email before running, e.g. CERTBOT_EMAIL=you@example.com bash web_and_tls.sh}"

echo "== 1/4: Read generated keys =="
source "$APP_DIR/secrets/supabase_keys.txt"
LIVEKIT_KEY=$(grep -oP '^\s*\K[a-f0-9]{32}(?=:)' "$APP_DIR/livekit/livekit.yaml" | head -1)
LIVEKIT_SECRET=$(grep -oP ': \K[a-f0-9]{64}$' "$APP_DIR/livekit/livekit.yaml" | head -1)

echo "== 2/4: Write web/.env.local =="
cat > "$APP_DIR/web/.env.local" <<EOF
NEXT_PUBLIC_SUPABASE_URL=https://${DOMAIN}/api
NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY}
LIVEKIT_API_KEY=${LIVEKIT_KEY}
LIVEKIT_API_SECRET=${LIVEKIT_SECRET}
NEXT_PUBLIC_LIVEKIT_URL=wss://${DOMAIN}
EOF

echo "== 3/4: Build & run web app (Docker) =="
cat > "$APP_DIR/web/Dockerfile" <<'EOF'
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.env.local ./.env.local
EXPOSE 3000
CMD ["npm", "start"]
EOF

cd "$APP_DIR/web"
docker build -t alo-web .
docker rm -f alo-web 2>/dev/null || true
docker run -d --name alo-web --restart unless-stopped -p 3000:3000 --env-file .env.local alo-web

echo "== 4/4: Nginx + TLS =="
sudo apt-get install -y nginx certbot python3-certbot-nginx

sudo tee /etc/nginx/sites-available/alo >/dev/null <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location ~ ^/(rtc|settings|validate) {
        proxy_pass http://127.0.0.1:7880;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/alo /etc/nginx/sites-enabled/alo
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect

echo ""
echo "== خلص =="
echo "الموقع: https://${DOMAIN}"
echo "تذكير: افتح بورت 7880 TCP على الـNginx كـstream أو استخدم wss مباشرة عبر البورت المفتوح أصلاً بالـfirewall."
