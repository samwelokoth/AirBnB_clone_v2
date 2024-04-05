#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Check if Nginx is installed, if not, install it
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt update && sudo apt install -y nginx
else
    echo "Nginx is already installed."
fi

# Create directories if they don't exist
sudo mkdir -p /data/web_static/releases/{test} || { echo "Error creating directories"; exit 1; }

# Create a fake HTML file with some sample content
cat > "/data/web_static/releases/test/index.html" << EOF
<html>
<body>
<h1>Hello from web_static</h1>
</body>
</html>
EOF || { echo "Error writing index.html"; exit 1; }

# Delete existing symlink and create new one
rm -f "/data/web_static/current" || { echo "Error removing current symlink"; exit 1; }
ln -sf "/data/web_static/releases/\$(ls -tdR /data/web_static/releases | grep '\.\/test$')" "/data/web_static/current" || { echo "Error creating current symlink"; exit 1; }

# Change ownership of the /data/ folder to the ubuntu user and group
sudo chown -R ubuntu:ubuntu /data || { echo "Error changing permissions"; exit 1; }

# Update the Nginx configuration to serve the content of /data/web_static/current/ to hbnb_static
sed -i "s|^(.*\/hbnb_static)|\\1\/web_static\/current|g" /etc/nginx/sites-available/default || { echo "Error modifying Nginx config"; exit 1; }

# Restart Nginx to apply changes
sudo service nginx reload || { echo "Error restarting Nginx"; exit 1; }

echo "Web static setup completed successfully!"
