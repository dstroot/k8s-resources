## Traefik Recipe

This recipe will deploy [traefik](https://docs.traefik.io/) on Kubernetes.  

https://docs.traefik.io/user-guide/kubernetes/
https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948#.u0ovjuj7y
https://capgemini.github.io/kubernetes/kube-traefik/
https://blog.osones.com/en/kubernetes-ingress-controller-with-traefik-and-lets-encrypt.html


**Table of Contents**

  - [Sqlpad Recipe](#guestbook-example)
    - [Prerequisites](#prerequisites)
    - [Quick Start](#quick-start)
    - [Step One: Start up the redis master](#step-one-start-up-the-redis-master)
      - [Define a Deployment](#define-a-deployment)
      - [Define a Service](#define-a-service)
      - [Create a Service](#create-a-service)
      - [Finding a Service](#finding-a-service)
        - [Environment variables](#environment-variables)
        - [DNS service](#dns-service)
      - [Create a Deployment](#create-a-deployment)
      - [Optional Interlude](#optional-interlude)
    - [Step Two: Start up the redis slave](#step-two-start-up-the-redis-slave)
    - [Step Three: Start up the guestbook frontend](#step-three-start-up-the-guestbook-frontend)
      - [Using 'type: LoadBalancer' for the frontend service (cloud-provider-specific)](#using-type-loadbalancer-for-the-frontend-service-cloud-provider-specific)
    - [Step Four: Cleanup](#step-four-cleanup)
    - [Troubleshooting](#troubleshooting)
    - [Appendix: Accessing the guestbook site externally](#appendix-accessing-the-guestbook-site-externally)
      - [Google Compute Engine External Load Balancer Specifics](#google-compute-engine-external-load-balancer-specifics)

The Recipe consists of:

deployed a node.js based application called Sqlpad.  The application can be used to interact with several popular SQL databases.

**Note**:  If you are running this example on a [Google Container Engine](https://cloud.google.com/container-engine/) installation, see [this Google Container Engine guestbook walkthrough](https://cloud.google.com/container-engine/docs/tutorials/guestbook) instead. The basic concepts are the same, but the walkthrough is tailored to a Container Engine setup.

### Prerequisites

This example requires a running Kubernetes cluster. First, check that kubectl is properly configured by getting the cluster state:




### Secure All The Things

We’re just going to generate a self-signed certificate for this tutorial, but any certificate/key pair will work. Run the following command to generate your certificate and dump the certificate and private key.

```
openssl req \
        -newkey rsa:2048 -nodes -keyout tls.key \
        -x509 -days 365 -out tls.crt
```

Now that we have the certificate, we’ll use kubectl to store it as a secret. We’ll use this so our pods running Traefik can access it.

```
kubectl create secret -n kube-system generic traefik-cert \
        --from-file=tls.crt \
        --from-file=tls.key
```


Now let’s take this configuration and store it in a ConfigMap to be mounted as a volume in the Traefik pods.


```
kubectl create configmap -n kube-system traefik-conf --from-file=traefik.toml
```

`echo "$(minikube ip) cheeses.local" | sudo tee -a /etc/hosts`
