#!/bin/bash
if [[ -z $REDIS_PASS ]];
then
      exec $@ --redis-port=$REDIS_PORT --redis-host=$REDIS_HOST  --redis-db=${REDIS_DB} --http-u ${WEB_USER} --http-p ${WEB_PASS}
else
      exec $@ --redis-port=$REDIS_PORT --redis-host=$REDIS_HOST --redis-password=${REDIS_PASS} --redis-db=${REDIS_DB} --http-u ${WEB_USER} --http-p ${WEB_PASS}
fi
