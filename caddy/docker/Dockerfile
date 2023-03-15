FROM zzrot/alpine-caddy:latest
# https://github.com/ZZROTDesign/alpine-caddy

# Originally I used alpine’s package repository for Hugo, but 
# I found out recently the version there is out of date. 
# So I now download the release directly from github, set to the 
# latest, 0.25.1 version.
# 
# I also added the CA bundle (RUN apk add --no-cache ca-certificates) 
# as down the road I might need to make https requests.
# 
# Then I replace (COPY Caddyfile /etc/Caddyfile) the default 
# zzrot’s config with mine (more about it below).
# 
# Finally I expose port 3000 (EXPOSE 3000) for traefik to auto detect it.

MAINTAINER Dan Stroot <dan.stroot@gmail.com>

ENV HUGO_VERSION=0.25.1

# ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp

ADD https://github.com/gohugoio/hugo/releases/download/v0.25.1/hugo_0.25.1_Linux-64bit.tar.gz /tmp

# RUN ls /tmp

# RUN ls /tmp/hugo

# RUN tar -xf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp \
# RUN tar -xf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp \
RUN mv /tmp/hugo /usr/bin/hugo \
    && rm -rf /tmp/hugo_${HUGO_VERSION}_linux_amd64

RUN apk add --no-cache ca-certificates

COPY Caddyfile /etc/Caddyfile

EXPOSE 3000


