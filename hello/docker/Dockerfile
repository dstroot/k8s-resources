# Guide here:
# https://github.com/KyleAMathews/docker-nginx

# Build from this repo's image
FROM kyma/docker-nginx

# Example if you wanna swap the default server file
# COPY path/to/your/default /etc/nginx/sites-enabled/default

# Add content
COPY www/ /var/www

CMD 'nginx'