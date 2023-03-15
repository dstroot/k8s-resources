#!/usr/bin/env bash

set -eEo pipefail

ALGO_DIR="$(dirname "${0}")"

usage() {
    retcode="${1:-0}"
    echo "To run algo from Docker:"
    echo ""
    echo "docker run --cap-drop ALL -it -v <path to configs>:/${ALGO_DIR}/configs -v <path to config.cfg>:/${ALGO_DIR}/config.cfg trailofbits/algo:latest"
    echo ""
    exit ${retcode}
}

if [ ! -d configs ] ; then
  echo "Looks like you're not bind-mounting your configs into this container."
  echo "This is something you want to do, or you'll lose your configurations"
  echo "as soon as algo finishes."
  echo ""
  usage -1
fi

if [ ! -f config.cfg ] ; then
  echo "Looks like you're not bind-mounting your config.cfg into this container."
  echo "algo needs a configuration file to run."
  echo ""
  usage -1
fi

if [ ! -e /dev/console ] ; then
  echo "Looks like you're trying to run this container without a TTY."
  echo "If you don't pass `-t`, you can't interact with the algo script."
  echo ""
  usage -1
fi

# Ensure that `config.cfg` has the appropriate line endings
tr -d '\r' < config.cfg > config.cfg.new
cat config.cfg.new > config.cfg
rm -f config.cfg.new

exec "${ALGO_DIR}"/algo "${ALGO_ARGS}"