# ================ commands.bash ================

# connect to the server
ssh -i ~/.ssh/cloud1_key ubuntu@DROPLET_IP_Public

# ------------------ SSH & Basic Connection

# SSH into your server
ssh -i ~/.ssh/cloud1_key ubuntu@DROPLET_IP_Public

# Check if server is reachable (before SSH)
ping DROPLET_IP_Public

# Check SSH port is open (from your laptop)
nc -zv DROPLET_IP_Public 22

# Check DNS resolution (if using domain)
dig +short mgcloud1.webhop.me
nslookup mgcloud1.webhop.me

# ------------------ Docker Commands

# List running containers
docker ps

# List ALL containers (including stopped)
docker ps -a


# List Docker volumes
docker volume ls

# List Docker networks
docker network ls

# Inspect a specific container
docker inspect cloud1_nginx

# Check container resource usage
docker stats

# Execute command inside container
docker exec cloud1_nginx nginx -t          # Test nginx config
docker exec cloud1_nginx cat /etc/nginx/nginx.conf
docker exec cloud1_wordpress ls -la /var/www/html
docker exec cloud1_mariadb mysql -u wp_user -p"WpCloud1Secure2024!" -e "SHOW DATABASES;"

# Restart a specific container
docker restart cloud1_nginx

# Stop a specific container
docker stop cloud1_nginx

# ------------------ Check wordpress and Test HTTP , certificates, and cron

# Test HTTP (should redirect to HTTPS)
curl -I http://localhost/
curl -I http://mgcloud1.webhop.me

# Test HTTPS (ignore cert warning with -k)
curl -Ik https://localhost/
curl -Ik https://mgcloud1.webhop.me

# -------------------- Check certificates & crontab

# find certificate and must see /live folder
sudo ls -la /opt/cloud1/certbot/

# If we find we go deeper :

sudo ls -la /opt/certbot/live/

# Check content certificate

sudo openssl x509 -in /opt/certbot/live/YOUR_DOMAIN_NAME/fullchain.pem -text -noout
sudo openssl x509 -in /opt/certbot/live/cloud1-abed.sytes.net/fullchain.pem -text -noout

# Check cron
sudo crontab -l

#----------------- Test mariadb from out
# From your laptop (or droplet host) - (Should FAIL)
mysql -h YOUR_DROPLET_IP -P 3306 -u wp_user -p

# From Inside the Docker Network - (Should WORK)
docker run --rm -it --network cloud1_backend alpine sh

# ---------------- Cleanup / Reset Commands

# soft reset (keep volumes and networks) 
docker compose down
docker compose up -d

# Stop and remove ALL containers
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null

# Remove ALL volumes (this deletes WordPress data and database!)
docker volume rm $(docker volume ls -q) 2>/dev/null

# Remove ALL networks (except default bridge)
docker network prune -f

# Remove the project directory
sudo rm -rf /opt/cloud1

# Remove cron job
sudo crontab -l | grep -v "Certbot renewal" | sudo crontab -

# Exit
exit

# ---------------------- ansibale commands

# Encrypt 
ansible-vault encrypt group_vars/all/vault.yml

# Decrypt
ansible-vault decrypt group_vars/all/vault.yml

# +++++++++++++++++ check Communication Proof 

# From nginx container, reach wordpress
docker exec cloud1_nginx ping -c 1 wordpress

# From wordpress container, reach mariadb
docker exec cloud1_wordpress ping -c 1 mariadb

# From phpmyadmin container, reach both
docker exec cloud1_phpmyadmin ping -c 1 mariadb
docker exec cloud1_phpmyadmin ping -c 1 nginx

# +++++++++++++++ Volumes
# List volumes
docker volume ls
# DRIVER    VOLUME NAME
# local     cloud1_wordpress_data
# local     cloud1_db_data

# Inspect a volume
docker volume inspect cloud1_db_data
# Shows Mountpoint, CreatedAt, etc.

# See actual files on host
sudo ls -la $(docker volume inspect -f '{{ .Mountpoint }}' cloud1_wordpress_data)

# See database files
sudo ls -la $(docker volume inspect -f '{{ .Mountpoint }}' cloud1_db_data)

# ++++++++++++++ Orchestration

# Start entire stack
cd /opt/cloud1 && docker compose up -d