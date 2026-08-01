#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=== PPK Concesionarios - bootstrap started $(date -u) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg git unzip

# --- Docker Engine + Compose plugin ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# --- AWS CLI v2 (used by the app's boto3 client indirectly is not required,
# but is handy for the operations team, and later for the attacker abusing
# the instance role after privilege escalation) ---
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# --- Developer account ---
# Created so the dev team can manage the sandbox app directly on the box.
# Its password is intentionally the same one baked into the dev
# environment's .env file (DEV_PASSWORD) - a credential-reuse mistake.
id -u pepe >/dev/null 2>&1 || useradd -m -s /bin/bash pepe
echo "pepe:${dev_password}" | chpasswd

# Password auth was only meant to be temporary while pepe's SSH key was
# being set up, and only for that one account - but it was never revisited.
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-pepe-password-auth.conf <<'SSHDCFG'
Match User pepe
    PasswordAuthentication yes
SSHDCFG
systemctl restart ssh

# --- Sudoers misconfiguration ---
# The developer was allowed to inspect the application logs as root without
# a password, since `docker logs` requires elevation and nobody wanted to
# hand out full sudo. `less` is not sandboxed against its own shell escape,
# so this ends up being a full root shell (classic GTFOBins entry).
mkdir -p /var/log/ppk-portal
touch /var/log/ppk-portal/app.log
chmod 644 /var/log/ppk-portal/app.log

cat > /etc/sudoers.d/90-pepe-devtools <<'SUDOERS'
pepe ALL=(root) NOPASSWD: /usr/bin/less /var/log/ppk-portal/*.log
SUDOERS
chmod 440 /etc/sudoers.d/90-pepe-devtools
visudo -c

# --- Application source ---
rm -rf /opt/aws-security-labs
git clone --depth 1 "${github_repo_url}" /opt/aws-security-labs
APP_SRC="/opt/aws-security-labs/lab-1-ppk-concesionarios/app"

mkdir -p /opt/ppk-portal
rm -rf /opt/ppk-portal/app
cp -r "$APP_SRC" /opt/ppk-portal/app

# --- Environment files ---
# Production: no developer/debug material at all.
cat > /opt/ppk-portal/prod.env <<ENVEOF
APP_MODE=production
SECRET_KEY=${app_secret_key}
DATABASE_URL=mysql+pymysql://${db_username}:${db_password}@${db_host}:${db_port}/${db_name}
S3_BUCKET_NAME=${bucket_name}
AWS_REGION=${aws_region}
ENVEOF

# Development: same DB, but also carries the developer's working login,
# which is exactly what turns the LFI into a foothold on the box.
cat > /opt/ppk-portal/dev.env <<ENVEOF
APP_MODE=development
SECRET_KEY=${app_secret_key}
DATABASE_URL=mysql+pymysql://${db_username}:${db_password}@${db_host}:${db_port}/${db_name}
S3_BUCKET_NAME=${bucket_name}
AWS_REGION=${aws_region}
DEV_USERNAME=pepe
DEV_PASSWORD=${dev_password}
ENVEOF

chmod 640 /opt/ppk-portal/prod.env /opt/ppk-portal/dev.env

# --- nginx: routes both hostnames to the right container by Host header ---
cat > /opt/ppk-portal/nginx.conf <<'NGINXEOF'
server {
    listen 80;
    server_name dev.ppkconcesionario.com;

    location / {
        proxy_pass http://app_dev:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 80 default_server;
    server_name ppkconcesionario.com;

    location / {
        proxy_pass http://app_prod:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINXEOF

# --- docker-compose: nginx + one prod app + one dev app, same image ---
cat > /opt/ppk-portal/docker-compose.yml <<'COMPOSEEOF'
services:
  app_prod:
    build: ./app
    env_file: prod.env
    restart: unless-stopped

  app_dev:
    build: ./app
    env_file: dev.env
    restart: unless-stopped
    volumes:
      - /var/log/ppk-portal:/var/log/ppk-portal

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app_prod
      - app_dev
    restart: unless-stopped
COMPOSEEOF

cd /opt/ppk-portal
docker compose up -d --build

echo "=== PPK Concesionarios - bootstrap finished $(date -u) ==="
