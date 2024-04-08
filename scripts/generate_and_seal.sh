#!/bin/bash
set -e

# FIXME: this script is too convoluted

environment=$1
if [ "$environment" == "brain12" ]; then
    env="brain12"
else
    echo "Invalid environment: $environment"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f "${SCRIPT_DIR}/../cert/$env/public.crt" ]; then
    echo "Public certificate not found in the repository."
    exit 1
fi

# dex/config.yaml
secret_file="$SCRIPT_DIR/../env/$env/dex/dex_config_secret.json "
sealed_secret_file="$SCRIPT_DIR/../env/$env/dex/dex_config_secret_sealed.json"
kubectl create secret generic dex -n auth --dry-run=client --from-file=$SCRIPT_DIR/../env/$env/dex/config.yaml \
-o json > $secret_file
kubeseal --cert "${SCRIPT_DIR}/../cert/$env/public.crt" <$secret_file > $sealed_secret_file

# dex/custom_theme
secret_file="$SCRIPT_DIR/../env/$env/dex/custom_theme/custom_theme_secret.json"
sealed_secret_file="$SCRIPT_DIR/../env/$env/dex/custom_theme/custom_theme_secret_sealed.json"
kubectl create secret generic dex-custom-theme-secret -n auth --dry-run=client \
--from-file=$SCRIPT_DIR/../env/$env/dex/custom_theme/favicon.png \
--from-file=$SCRIPT_DIR/../env/$env/dex/custom_theme/logo.png \
--from-file=$SCRIPT_DIR/../env/$env/dex/custom_theme/styles.css \
-o json > $secret_file
kubeseal --cert "${SCRIPT_DIR}/../cert/$env/public.crt" <$secret_file > $sealed_secret_file

# oidc-authservice/oidc-authservice-client-parameters.env
secret_file="$SCRIPT_DIR/../env/$env/oidc-authservice/oidc-authservice-client-parameters-secret.json"
sealed_secret_file="$SCRIPT_DIR/../env/$env/oidc-authservice/oidc-authservice-client-parameters-secret-sealed.json"
kubectl create secret generic oidc-authservice-client-parameters-secret \
-n istio-system --dry-run=client --from-env-file="${SCRIPT_DIR}/../env/$env/oidc-authservice/oidc-authservice-client-parameters.env" \
-o json > $secret_file
kubeseal --cert "${SCRIPT_DIR}/../cert/$env/public.crt" <$secret_file > $sealed_secret_file

# oidc-authservice/oidc-authservice-parameters.env
secret_file="$SCRIPT_DIR/../env/$env/oidc-authservice/oidc-authservice-parameters-secret.json"
sealed_secret_file="$SCRIPT_DIR/../env/$env/oidc-authservice/oidc-authservice-parameters-secret-sealed.json"
kubectl create secret generic oidc-authservice-parameters-secret \
-n istio-system --dry-run=client --from-env-file="${SCRIPT_DIR}/../env/$env/oidc-authservice/oidc-authservice-parameters.env" \
-o json > $secret_file
kubeseal --cert "${SCRIPT_DIR}/../cert/$env/public.crt" <$secret_file > $sealed_secret_file

# centraldashboard/params.env
secret_file="$SCRIPT_DIR/../env/$env/centraldashboard/centraldashboard-parameters-secret.json"
sealed_secret_file="$SCRIPT_DIR/../env/$env/centraldashboard/centraldashboard-parameters-secret-sealed.json"
kubectl create secret generic centraldashboard-parameters \
-n kubeflow --dry-run=client --from-env-file="${SCRIPT_DIR}/../env/$env/centraldashboard/params.env" \
-o json > "${SCRIPT_DIR}/../env/$env/centraldashboard/centraldashboard-parameters-secret.json"
kubeseal --cert "${SCRIPT_DIR}/../cert/$env/public.crt" <$secret_file > $sealed_secret_file
