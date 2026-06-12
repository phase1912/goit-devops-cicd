#!/bin/bash

echo "Starting installation of dev tools..."

sudo apt update -y

sudo apt install -y curl ca-certificates gnupg lsb-release python3 python3-pip python3-venv

if command -v python3 > /dev/null 2>&1
then
    echo "Python is already installed:"
    python3 --version
else
    echo "Installing Python..."
    sudo apt install -y python3 python3-pip
fi

if command -v docker > /dev/null 2>&1
then
    echo "Docker is already installed:"
    docker --version
else
    echo "Installing Docker..."

    sudo mkdir -p /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y

    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    echo "Docker installed successfully"
fi

if docker compose version > /dev/null 2>&1
then
    echo "Docker Compose is already installed:"
    docker compose version
else
    echo "Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
fi

if python3 -m django --version > /dev/null 2>&1
then
    echo "Django is already installed:"
    python3 -m django --version
else
    echo "Installing Django..."
    python3 -m pip install --user Django
fi

echo ""
echo "Installation finished."
echo "Installed versions:"
docker --version 2>/dev/null
docker compose version 2>/dev/null
python3 --version
python3 -m django --version 2>/dev/null