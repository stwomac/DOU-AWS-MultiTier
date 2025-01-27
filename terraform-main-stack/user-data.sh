#!/bin/sh

# Image names of that the containers will use
IMAGE_NAME_1="womackst9/dou-api:latest"
IMAGE_NAME_2="womackst9/dou-frontend:latest"

# Name of the files that hold the docker images
IMAGE_FILE_1="/mnt/efs/gold-api.tar"
IMAGE_FILE_2="/mnt/efs/gold-frontend.tar"

# This set installs the necessary libraries for EFS
echo $var1 >> /home/ubuntu/var.txt
echo "${var1}" >> /home/ubuntu/var1.txt
cd /home/ubuntu
apt-get update -y
apt-get -y install git binutils rustc cargo pkg-config libssl-dev gettext
git clone https://github.com/aws/efs-utils
cd efs-utils
sh ./build-deb.sh
apt-get -y install ./build/amazon-efs-utils*deb
mkdir -p /mnt/efs
chmod 777 /mnt/efs
mount -t efs -o tls ${var1}:/ /mnt/efs
echo "${var1}.efs.us-east-1.amazonaws.com:/ /mnt/efs efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
# Note, the above process continues even while amazon says is initialized, so give it a couple of extra minutes before checking.
# (Optional) Sleep to ensure everything is ready

# Mount all from /etc/fstab
mount -a

# this set installs the necessary libraries for docker
cd /home/ubuntu
apt-get -y update
apt-get -y install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Optional Sleep, usefull if you are running this without a domain and instead just the load balancer
sleep 60

# This checks for the backend image in the EFS, and if not there dowloads and puts it there
if [ -f "$IMAGE_FILE_1" ]; then
    echo "Gold image file for backend found. Loading Docker image from '$IMAGE_FILE_1'..."
    docker load -i "$IMAGE_FILE_1"
    echo "Docker image loaded successfully."
else
    echo "Gold image file for backend not found. Pulling image '$IMAGE_NAME_1' from Docker registry..."
    docker pull "$IMAGE_NAME_1"
    if [ $? -eq 0 ]; then
      echo "Successfully pulled image '$IMAGE_NAME_1'."
      echo "Saving the pulled image to '$IMAGE_FILE_1'..."
      docker save -o "$IMAGE_FILE_1" "$IMAGE_NAME_1"
      echo "Docker image saved locally as '$IMAGE_FILE_1'."
    else
      echo "Failed to pull the image for backend. Please check your Docker configuration or image name."
      exit 1
    fi
fi

# This checks for the frontend image in the EFS, and if not there dowloads and puts it there
if [ -f "$IMAGE_FILE_2" ]; then
    echo "Gold image file for frontend found. Loading Docker image from '$IMAGE_FILE_2'..."
    docker load -i "$IMAGE_FILE_2"
    echo "Docker image loaded successfully."
else
    echo "Gold image file for frontend not found. Pulling image '$IMAGE_NAME_2' from Docker registry..."
    docker pull "$IMAGE_NAME_2"
    if [ $? -eq 0 ]; then
      echo "Successfully pulled image '$IMAGE_NAME_2'."
      echo "Saving the pulled image to '$IMAGE_FILE_2'..."
      docker save -o "$IMAGE_FILE_2" "$IMAGE_NAME_2"
      echo "Docker image saved locally as '$IMAGE_FILE_2'."
    else
      echo "Failed to pull the imagefor frontend . Please check your Docker configuration or image name."
      exit 1
    fi
fi

# This gets both the docker containers running together on the instance
echo "Running the Docker image for backend as a container..."

docker network create mynetwork
docker run -d --network mynetwork --name "web-server-backend" \
  -p 3000:3000 \
  "$IMAGE_NAME_1"

echo "Running the Docker image for frontend as a container..."
docker run -d --network mynetwork --name "web-server-frontend" \
  -p 4200:4200 \
  "$IMAGE_NAME_2"