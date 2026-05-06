# Self-host Next.js on Ubuntu

Guide for deploying this Next.js app on a Linux Ubuntu server with Nginx and HTTPS, using **PM2** or **Docker** on the server.

This project loads product records from **[ReqRes](https://reqres.in/)** collections (REST API). Create a project and API credentials at **[ReqRes App](https://app.reqres.in/)**, then set the variables in `.env` (see [`env.sample`](./env.sample)).

## Prerequisites

- Purchase a domain name
- Purchase a Linux Ubuntu server (for example a [DigitalOcean Droplet](https://www.digitalocean.com/products/droplets))
- Create an `A` DNS record pointing to your server IPv4 address

## SSH Setup

```bash
cd ~/.ssh
ssh-keygen
cat your_key_file_name.pub   # example: cat id_ed25519.pub
```

- Copy that key and paste it on your hosting platform
  - Go to **DigitalOcean Dashboard**
  - Settings → **Security → SSH Keys**
  - Add the key
- Run `nano ~/.ssh/config` and paste the configuration below (adjust host, IP, and key path as needed)

```text
Host my-server                   # example alias
    HostName 64.23.240.166       # your server IP or hostname
    PreferredAuthentications publickey
    User root
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_ed25519
```

- Log in to the server

```bash
ssh root@YOUR_IP    # example: ssh root@64.23.240.166
```

- Log out from the server

```bash
exit
```

## Setup basic server

### 1. Update and basic system setup

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential curl git ufw
```

### 2. Enable firewall

```bash
ufw allow OpenSSH
ufw allow http
ufw allow https
ufw enable
```

### 3. Install Node.js (LTS)

Use **nvm** (recommended for flexibility):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

nvm install --lts
node -v
npm -v
```

### 4. Install package managers (optional: pnpm or yarn)

```bash
npm install -g pnpm
# or
npm install -g yarn
```

## Connect to GitHub

### Step 1: Check if an SSH key exists

```bash
ls ~/.ssh
```

If you need a new key:

```bash
ssh-keygen
```

Press Enter for defaults.

### Step 2: Copy public key

```bash
cat ~/.ssh/id_ed25519.pub
```

### Step 3: Add to GitHub

GitHub → **Settings** → **SSH and GPG keys** → **New SSH key** → paste the key.

### Step 4: Test connection

```bash
ssh -T git@github.com
```

### Step 5: Clone via SSH

```bash
git clone git@github.com:username/repository.git
```

## Build a project

### 1. Build your Next.js app

```bash
git fetch --all
git reset --hard origin/main

cp env.sample .env
# Edit .env: ReqRes project ID and API key from https://app.reqres.in/

npm install
npm run build
```

Install PM2 globally if you have not yet:

```bash
npm install -g pm2
```

### 2. Start with PM2 (production mode)

**Option A — simplest**

```bash
pm2 start npm --name "nextjs-app" -- start
```

### 3. Save PM2 process (important)

```bash
pm2 save
pm2 startup
```

Run the command PM2 prints after `startup`.

### 4. Useful PM2 commands

```bash
pm2 list               # see running apps
pm2 logs               # view logs
pm2 restart nextjs-app
pm2 stop nextjs-app
pm2 delete nextjs-app   # or: pm2 delete <id>
pm2 reload nextjs-app   # zero-downtime reload
```

### 5. Use an ecosystem file (recommended)

Create `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [
    {
      name: "nextjs-app",
      script: "npm",
      args: "start",
      cwd: "/path/to/your/project",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },
    },
  ],
};
```

Run:

```bash
pm2 start ecosystem.config.js
```

## Setup Nginx

### 1. Check if Nginx is installed

```bash
nginx -v
```

If not:

```bash
sudo apt install nginx -y
```

### 2. Check directories exist

```bash
ls /etc/nginx/
```

You should see:

```text
sites-available
sites-enabled
```

If not:

```bash
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
```

### 3. Edit the site config (use sudo)

```bash
sudo nano /etc/nginx/sites-available/default
```

### 4. Example reverse proxy config

Replace `your-domain-or-ip` with your domain or server IP:

```nginx
server {
    listen 80;
    server_name your-domain-or-ip;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 5. Save in nano

- `Ctrl + O`, then Enter
- `Ctrl + X`

### 6. Enable config (if needed)

```bash
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
```

### 7. Test and restart Nginx

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### 8. Connect your domain

Point your domain’s `A` record at the server IP (same as in Prerequisites). Allow DNS to propagate before certificate issuance.

### 9. Install Certbot and the Nginx plugin

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx
```

- Enter your email
- Accept the terms

---

## Local development

```bash
cp env.sample .env
```

Edit `.env` with your [ReqRes App](https://app.reqres.in/) project ID and API key.

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Self-host with Docker (Ubuntu server)

Run the production **standalone** bundle in Docker **on your VPS** (`node server.js`, not `next start`). Details are in [`Dockerfile`](./Dockerfile).

Use this path when you want containers instead of Node + PM2. Prerequisites (domain, Ubuntu server, DNS, SSH) match [Prerequisites](#prerequisites). Commands below are meant to run **on the server** over SSH.

You can still follow [Setup basic server](#setup-basic-server) steps **1** (updates, packages) and **2** (firewall). **Skip** installing Node.js / npm there and skip the PM2-based **[Build a project](#build-a-project)** section — Docker builds and runs the app for you.

### 1. Install Docker Engine and Compose plugin

Official reference: **[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)**.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME:-$VERSION_ID}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify:

```bash
docker version
docker compose version
```

### 2. Build and start

From the directory that contains `compose.yml`:

```bash
docker compose build
docker compose up -d
```

### 3. Operations

```bash
docker compose ps
docker compose logs -f app
docker compose restart app
docker compose stop
docker compose down
docker compose build
docker compose up -d
```

Stop and remove:

```bash
docker stop next-app
docker rm next-app
```
