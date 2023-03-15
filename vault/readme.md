# Kubernetes Secrets - not so Secret

Kubernetes [Secrets](http://kubernetes.io/docs/user-guide/secrets/walkthrough/) are base64 encoded name/value pairs. Secrets can be consumed as volumes, or as environment variables. They are very handy to use, but they are not very "secret".  Base64 encoding is solely used so that binary data can be represented, it has no security value or context.

Take this secret.yaml file for example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: bXlzZWN1cmVwYXNzd29yZA==
```

The password above can be trivially decoded:

```shell
$ echo -n bXlzZWN1cmVwYXNzd29yZA== | base64 --decode
mysecurepassword
```

So if we were to store our configuration files in a repository with public or wide access we would be giving our secrets away.  It should be our goal to **not** store configuration or secrets in our repositories anyway according to the [Twelve Factor Philosophy](https://12factor.net/). So what to do?

### Introducing Vault

Vault is one of many tools that allow secure storage of credentials and keys.  We aren't going to do tool selection here - we are simply going to show you how to use Vault with Kubernetes and Kubernetes Secrets.

If you are unfamiliar with Vault this [tutorial](https://www.vaultproject.io/#/demo/0) is great and takes just 10 minutes.

First off we need Vault up and running.

#### Prerequisites

This assumes that you have a Kubernetes cluster installed and running, and that you have installed the `kubectl` command line tool somewhere in your path.


1. Configure a volume for persistent storage.  On Google's cloud this is a simple as:
    ```shell
    $ gcloud compute disks create --size 10gb vault
    ```

2. Create a cert locally:
    ```shell
    $ mkdir -p cert
    $ openssl req -x509 -newkey rsa:2048 -nodes -keyout cert/vault.key -out cert/vault.crt -days 730 -subj "/CN=127.0.0.1:8200"
    ```

    Notes: Basically, in order to use TLS in Go, now you MUST specify a CN in the subject field. Wildcards are supported, but '*' does not match '.' If you're using self signed certs or have a closed ecosystem of SSL certs in your environment, it's possible that CN=* or CN=*.example.com might just be fine for you.

    Examine your cert: `openssl x509 -in vault.crt -text -noout`

3. Then create a Kubernetes secret to store the cert:
    ```shell
    $ cd cert
    $ kubectl create secret generic vault-cert --from-file=./vault.crt --from-file=./vault.key
    ```

2. Fire up a Vault pod on Kubernetes using the official Docker image:
    ```yaml
    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: vault-config
      namespace: default
    data:
      # Don't really disable TLS!
      # This is just to get something up quickly
      vault.hcl: |
        backend "file" {
          path = "/vault/file"
        }

        listener "tcp" {
         address = "127.0.0.1:8200"
         tls_disable = 1
        }
    ---
    kind: Deployment
    apiVersion: extensions/v1beta1
    metadata:
      name: vault
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: vault
        spec:
          containers:
          - name: vault
            # Note IPC_LOCK is required in order for Vault to lock
            # memory, which prevents it from being swapped to disk.
            # This is highly recommended for security purposes.
            securityContext:
              capabilities:
                add:
                - IPC_LOCK
            image: vault:v0.6.0
            args:
            - server
            ports:
            - containerPort: 8200
            resources:
              requests:
                cpu: 10m
                memory: 10Mi
            volumeMounts:
              - name: vault-volume
                mountPath: /vault/file
              - name: vault-config
                mountPath: /vault/config
          restartPolicy: Always
          volumes:
          - name: vault-volume
            gcePersistentDisk:
              pdName: vault  
              fsType: ext4
          - name: vault-config
            configMap:
              name: vault-config
          - name: vault-cert
            secret:
              name: vault-cert
    ```
3. Get the pod name:
    ```shell
    $ kubectl get pods
    NAME                              READY     STATUS    RESTARTS   AGE
    vault-2553328298-abktj            1/1       Running   0          15h
    ```
4. Use kubectl to establish port forwarding from the pod to your local machine so you can interact with it:
    ```shell
    $ kubectl port-forward vault-2553328298-abktj 8200:8200
    Forwarding from 127.0.0.1:8200 -> 8200
    Forwarding from [::1]:8200 -> 8200
    ```
5. Install the Vault CLI and server (for dev purposes) on your local machine.  You can download Vault as a precompiled binary from [here](https://www.vaultproject.io/downloads.html) or use Homebrew:
    ```shell
    $ brew install vault
    ```
6. Set your VAULT_ADDR environment variable:
    ```shell
    $ export VAULT_ADDR='http://localhost:8200'
    ```
7. If all is well you should now be able to interact with the vault installation on Kubernetes:   
    ```shell
    $ vault status
    ```
8. ==SETUP VAULT==
9. ==STORE A SECRET==
8. Now we can directly consume a vault secret locally and turn it into a Kubernetes secret. This is an example of a shell script that we could commit to a public repository and our secret is still very much a **secret**.  
    ```shell
    #!/bin/bash
    PASSWORD="$(vault read -field=value secret/password | base64)"

    # Create YAML object from stdin
    cat <<EOF | kubectl create -f -
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysecret
    type: Opaque
    data:
      password: "${PASSWORD}"
    EOF
    ```





backend "file" {
  path = "/vault"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = 1
  tls_cert_file = "/blah"
  tls_key_file = "blahblah.
}

telemetry {
  statsd_address = "statsd:8125"
  disable_hostname = true
}



❯ export VAULT_ADDR='http://130.211.126.76:8200/'


https://www.vaultproject.io/docs/config/index.html#path
https://stedolan.github.io/jq/
https://github.com/prometheus/statsd_exporter
https://hub.docker.com/_/vault/

https://github.com/hashicorp/vault/pull/1415
http://www.devoperandi.com/vault-in-kubernetes/
http://chairnerd.seatgeek.com/secret-management-with-vault/



Use kubectl to establish local port forwarding:
`$ kubectl port-forward vault-1270652834-c1ghx 8200:8200`

Then export your local address:
`$ export VAULT_ADDR='http://localhost:8200'`

Then you should be able to use your local Vault CLI:
```
$ vault status
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Version:

High-Availability Enabled: false
```

View logs on the vault server:
```
$ k logs vault-1270652834-c1ghx
==> WARNING: Dev mode is enabled!

In this mode, Vault is completely in-memory and unsealed.
Vault is configured to only have a single unseal key. The root
token has already been authenticated with the CLI, so you can
immediately begin using the Vault CLI.

The only step you need to take is to set the following
environment variables:

    export VAULT_ADDR='http://127.0.0.1:8200'

The unseal key and root token are reproduced below in case you
want to seal/unseal the Vault or play with authentication.

Unseal Key: 07ca3523f2afc3c256e362e4016f4c9de2a6410b90446fbf40803cf12c406b19
Root Token: 36be02ac-8562-05f0-f1f8-1ff2a468c1b4

==> Vault server configuration:

                 Backend: inmem
              Listener 1: tcp (addr: "127.0.0.1:8200", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
                 Version: Vault v0.6.0

==> Vault server started! Log data will stream in below:
```

next unseal the vault
then authenticate
then use it

```
$ vault write secret/hello value=world
Success! Data written to: secret/hello

$ vault read secret/hello
Key                    	Value
---                    	-----
refresh_interval       	720h0m0s
value                  	world

$ vault list secret
Keys
hello
```



### Kubernetes Kompanion

Log into Vault
List secrets (Note secrets can be enumerated and they can have additional variables)
Using an additional variable to identify the secret name we can create all the keys
for that grouping and create a secret.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mssql-secret  #<- Vault variable
type: Opaque
data:
  password: MjdVbXdGWWVmTlVl
  username: TE1QMkJPeU5sZEI=
```
