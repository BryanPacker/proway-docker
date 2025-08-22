# This script is responsible for deploying the Pizzaria project in an idempotent way
# step 1 - Installing required packages
# step 2 - Cloning and updating latest changs
# step 3 - Kill in the ports the application need 
# step 4 - Change necessary things at code
# step 5 - Add a cron job restarting the application and ensuring it's updated

#!/usr/bin/env bash

# Installing required packages
apt update && apt install -y docker.io git docker-compose cron lsof

for tools in docker cron; do
 systemctl start $tools
 systemctl enable $tools
done

# Navigate to root directory (required for repository management)
cd /root

# Clone the repository if it does not exist, otherwise pull the latest changes
if [ ! -d "proway-docker" ]; then
    git clone https://github.com/BryanPacker/proway-docker.git
    cd proway-docker
elif [ ! -d "proway-docker/.git" ] || [ ! -f "proway-docker/pizza.yml" ]; then
    # Folder exists but is not a valid git repository -> remove and re-clone
    rm -rf proway-docker
    git clone https://github.com/BryanPacker/proway-docker.git
    cd proway-docker
else
    cd proway-docker
     # Use git reset --hard to ensure idempotency (restores deleted files)
    git fetch origin
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
    [ -f projeto_pizza.sh ] && chmod +x /root/proway-docker/projeto_pizza.sh
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
touch /root/proway-docker/cron.log
echo "$(date '+%c'): Cron job executed successfully!" > /root/proway-docker/cron.log

echo " --------------------------------------------- "
echo " Application running in http://$SERVER_IP:8080 "
echo " --------------------------------------------- "
