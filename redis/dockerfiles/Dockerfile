FROM node:6.3.1-slim

RUN npm install redis-commander

WORKDIR /node_modules/redis-commander

ENV REDIS_HOST="redis"
ENV REDIS_PASS=""
ENV REDIS_DB=0
ENV REDIS_PORT=6379
ENV WEB_USER="user"
ENV WEB_PASS="pass"

COPY docker-entrypoint.sh ./
ENTRYPOINT ["./docker-entrypoint.sh"]

EXPOSE 8081
CMD ["node", "bin/redis-commander.js"]
