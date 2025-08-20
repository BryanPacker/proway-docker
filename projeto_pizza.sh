# This script is responsible for deploying the Pizzaria project in an idempotent way
#!/usr/bin/env bash

# Installing required packages
apt update && apt install -y docker.io git docker-compose cron lsof

# Navigate to root directory (required for repository management)
cd /root

# Clone the repository if it does not exist, otherwise pull the latest changes
if [ ! -d "proway-docker" ]; then
    git clone https://github.com/BryanPacker/proway-docker.git
    cd proway-docker
elif [ ! -d "proway-docker/.git" ]; then
    # Folder exists but is not a valid git repository -> remove and re-clone
    rm -rf proway-docker
    git clone https://github.com/BryanPacker/proway-docker.git
    cd proway-docker
else
    cd proway-docker
    git pull
fi

# Kill processes running on ports 8080 and 5001
for porta in 8080 5001; do
    lsof -ti:$porta | xargs -r kill -9
done

# Define variables for server IP and frontend directory
SERVER_IP=$(hostname -I | awk '{print $1}')
FRONTEND_DIR="pizzaria-app/frontend"

# Update Dockerfile with the correct backend URL
if [ -f "$FRONTEND_DIR/Dockerfile" ]; then
    sed -i "s|REACT_APP_BACKEND_URL=http://.*:5001|REACT_APP_BACKEND_URL=http://$SERVER_IP:5001|g" "$FRONTEND_DIR/Dockerfile"
fi

# Update index.html with the correct backend URL
if [ -f "$FRONTEND_DIR/public/index.html" ]; then
    sed -i "s|http://.*:5001|http://$SERVER_IP:5001|g" "$FRONTEND_DIR/public/index.html"
fi

# Deploy project using Docker Compose
cd /root/proway-docker/
docker-compose -f pizza.yml up -d --build

# Add cron job to keep the project updated (avoiding duplicate entries)
(crontab -l 2>/dev/null | grep -v "projeto_pizza.sh"; echo "*/5 * * * * /root/proway-docker/projeto_pizza.sh") | crontab -

# Log last execution (overwrites instead of appending)
echo "$(date '+%c'): Cron job executed successfully!" > /tmp/cron-test.log
