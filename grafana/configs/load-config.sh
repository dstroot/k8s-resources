#!/bin/bash

# Set constants
API_KEY="eyJrIjoiS0EzWGIxS0lPNUwwclNiOU9yZm1IZ0huT2VBQ3RINEEiLCJuIjoiQWRtaW4iLCJpZCI6MX0="
URL="localhost:3000"   # grafana:3000

# Load datasources
for file in *-datasource.json ; do
  if [ -e "$file" ] ; then
    echo "importing $file" &&
    curl --silent --fail --show-error \
      --header "Authorization: Bearer $API_KEY" \
      --header "Content-Type: application/json" \
      --request POST http://$URL/api/datasources \
      --data-binary "@$file" ;
    echo "" ;
  fi
done ;

# Load dashboards
for file in *-dashboard.json ; do
  if [ -e "$file" ] ; then
    echo "importing $file" &&
    ( echo '{"dashboard":'; \
      cat "$file"; \
      echo ',"overwrite":true,"inputs":[{"name":"DS_PROMETHEUS","type":"datasource","pluginId":"prometheus","value":"prometheus"}]}' ) \
    | jq -c '.' \
    | curl --silent --fail --show-error \
      --request POST http://admin:hellokitty@$URL/api/dashboards/import \
      --header "Content-Type: application/json" \
      --data-binary "@-" ;
    echo "" ;
  fi
done