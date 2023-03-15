FROM mhart/alpine-node  # https://github.com/mhart/alpine-node

RUN apk add --update \
    bash

RUN npm install sqlpad@{{SQLPAD_VERSION}} -g

ENV NODE_ENV=production \
    SQLPAD_PORT=3001 \
    SQLPAD_PASSPHRASE=you_need_something_secure_here

RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 3001
CMD ["sqlpad", "--dir /data"]
