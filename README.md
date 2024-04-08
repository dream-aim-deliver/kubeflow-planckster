
# Kubefow Planckster - CD

## Using sealed secrets

### Generating new certificates

Certificates that are used to seal secrets are generated using the following command:

```terminal
openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout "private.key" -out "public.crt" -subj "/CN=sealed-secret/O=sealed-secret"
```

Encrypting and decrypting larger files is done with a symmetric key, which is generated using the following command:

```terminal
openssl rand -base64 32 > symmetric.key
```

More info on how to generate new certificates can be found here:

https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md

### Creating k8s secrets based on the certificates to be used by bitnami

#### Creating the secret in the same namespace as the sealed secrets controller

```terminal
kubectl -n "kubeflow-planckster-secrets" create secret tls "bitnami-certificates" --cert="public.crt" --key="private.key"
```

or if working on a standalone manifest file

```terminal
kubectl -n "kubeflow-planckster-secrets" create secret tls "bitnami-certificates" --cert="public.crt" --key="private.key" --dry-run=client -o yaml > bitnami-certificates.yaml
```

#### Label the secret so that it can be found by the sealed secrets controller

```terminal
kubectl -n "kubeflow-planckster-secrets" label secret "bitnami-certificates" sealedsecrets.bitnami.com/sealed-secrets-key=active
```

or if working on a standalone manifest file

```terminal
kubectl patch -f bitnami-certificates.yaml -p '{"metadata": {"sealedsecrets.bitnami.com/sealed-secrets-key": "active"}}' --dry-run=client -o yaml > bitnami-certificates.yaml
```

#### Restarting the sealed secrets controller

```terminal
kubectl -n "kube-system" delete pod -l name=sealed-secrets-controller
```

## Sealing secrets

Make sure you have access to the private key and the public certificate: `private.key` and `public.crt`.

### Sealing env files

### Generating the secret JSON manifest

```terminal
 kubectl create secret generic env-secret -n istio-system --dry-run=client --from-env-file=file.env -o json > env-secret.json
```

#### Sealing the secret JSON manifest

```terminal
kubeseal --cert public.crt <env-secret.json > env-secret-sealed.json
```