# traefik-k8s-tls-example

This repo contains the Kubernetes resources used in my Medium post detailing the use of Traefik on Kubernetes with TLS

[Check out the post](https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948) for details on how to use this.




NOTE: The current setup works fine.  

Adds:
* Authentication on access to internal services
* Multiple pods of Traefik.  Right now we can only run one because it uses a disk.  The disk can only be mounted in one conatiner at a time.  The approach would have to use a KV store and then import the configuration into the KV and then you can scale Traefik to multiple nodes.




https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948#.sk1kyb69i

https://blog.osones.com/en/kubernetes-ingress-controller-with-traefik-and-lets-encrypt.html

https://github.com/ArchiFleKs/containers/blob/master/kubernetes/zero.vsense.fr/traefik.yml

https://github.com/settings/applications/497225

https://docs.traefik.io/toml/#acme-lets-encrypt-configuration

https://hub.docker.com/r/containous/traefik/tags/

need to create a volume for acme certs

To store Let's Encrypt certificates, we need to use a volume otherwise they will be regenerated every time the pod reboots.

`gcloud compute disks create --size 10GB acme`


https://eng.fromatob.com/post/2017/02/lets-encrypt-oauth-2-and-kubernetes-ingress/


https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx