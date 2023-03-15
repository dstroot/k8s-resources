#!/bin/bash

openssl req \
  -newkey rsa:4096 \
  -sha256 \
  -days 3650 \
  -nodes \
  -x509 \
  -subj "/C=US/ST=Distributed/L=Cloud/O=Cluster/CN=*.kuberecipes.com" \
  -extensions SAN \
  -config <( cat $( [[ "Darwin" -eq "$(uname -s)" ]]  && echo /System/Library/OpenSSL/openssl.cnf || echo /etc/ssl/openssl.cnf  ) \
    <(printf "[SAN]\nsubjectAltName='DNS.1:*.kuberecipes.com,DNS.2:vault,IP.1:127.0.0.1'")) \
  -keyout vault.key \
  -out vault.crt
