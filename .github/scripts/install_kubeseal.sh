#!/bin/bash
set -e
curl --silent --location --remote-name "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.4/kubeseal-0.24.4-linux-amd64.tar.gz"
tar -xzvf kubeseal-0.24.4-linux-amd64.tar.gz
chmod a+x kubeseal
sudo mv kubeseal /usr/local/bin/kubeseal
