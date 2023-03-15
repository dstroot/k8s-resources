# Let's Encrypt, OAuth 2, and Kubernetes Ingress

When running internal services within Kubernetes we'd want an easy solution to managing secure ingress. This guide is geared towards running services on the Google Container Engine (GKE). Note the GCP HTTP Load Balancer does not support TLS-SNI (at the time of this writing).

On GCP, the HTTP load balancers do not support TLS-SNI, which means you would need a new front-end IP address for each Service/SSL certificate you have. For internal services, this is a challenge.  Ideally you want to point a wildcard DNS entry to a single IP, like \*.mydomain.com and then have everything just work. 

Luckily, using a TCP load balancer with the [Nginx Ingress Controller](https://github.com/kubernetes/ingress) works well, and support TLS-SNI no problem.

### Steps:

1. Install a default http backend, 
2. Install the NGINX Ingress Controller (now we have ingress capability), then
3. Install Kube-Lego (it uses the ingress to automatically obtain Let's Encrypt certificates), finally
5. Point a domain or CNAME to this IP address.

NOTES: 

* HTTP->HTTPS redirection is automatically handled
* It may take a minute or two for certificates to be provisioned and loaded


Daemonset vs Deployment

https://github.com/kubernetes/ingress/tree/master/examples/daemonset/nginx

From readme: "In some cases, the Ingress controller will be required to be run at all the nodes in cluster. Using DaemonSet can achieve this requirement."

https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx

From the readme: "This example aims to demonstrate the deployment of an nginx ingress controller."

Why is the example directly mapping host ports?  Why not create a service with an external load balancer?  

https://github.com/kubernetes/ingress/tree/master/examples/static-ip/nginx




## Deploying the NGINX Ingress controller

#### Default Backend

First, we want to deploy a default backend.  The default backend is a just a service capable of handling all url paths and hosts the NGINX controller doesn't understand. This most basic implementation just returns a 404 page:

```yaml
# No changes below are necessary.
# create namespace first 
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-ingress
---
# The resources will be created in the order they appear in the file. 
# Therefore, it’s best to specify the service first, since that will 
# ensure the scheduler can spread the pods associated with the service 
# as they are created by the controller(s), such as Deployment.
# https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/
apiVersion: v1
kind: Service
metadata:
  name: default-http-backend
  namespace: nginx-ingress
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: default-http-backend
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-http-backend
  namespace: nginx-ingress
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: default-http-backend
    spec:
      containers:
      - name: default-http-backend
        # Any image is permissible as long as:
        # 1. It serves a 404 page at /
        # 2. It serves 200 on a /healthz endpoint
        image: gcr.io/google_containers/defaultbackend:1.0
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
```

#### NGINX Ingress Controller

Next, we deploy the actual [NGINX Ingress Controller](https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx
).  Note the default settings of this controller:

* serves a /healthz url on port 10254, as both a liveness and readiness probe
* takes a `--default-backend-service` argument pointing to the Service created above

NOTE: If you're running this ingress controller on a cloud provider, you should assume the provider also has a native ingress controller and set the annotation kubernetes.io/ingress.class: nginx in all ingresses meant for this controller. You might also need to open a firewall-rule for ports 80/443 of the nodes the controller is running on.

```yaml
# The resources will be created in the order they appear in the file. 
# No changes below are necessary.
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-controller
  namespace: nginx-ingress
data:
  proxy-connect-timeout: "15"
  proxy-read-timeout: "600"
  proxy-send-imeout: "600"
  hsts-include-subdomains: "false"
  body-size: "64m"
  server-name-hash-bucket-size: "256"
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ingress-lb
  labels:
    name: nginx-ingress-lb
  namespace: nginx-ingress
spec:
  template:
    metadata:
      labels:
        name: nginx-ingress-lb
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - image: gcr.io/google_containers/nginx-ingress-controller:0.8.3
        name: nginx-ingress-lb
        # imagePullPolicy: Always
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 80
          hostPort: 80
        - containerPort: 443
          hostPort: 443
        args:
        - /nginx-ingress-controller
        - --default-backend-service=nginx-ingress/default-http-backend
        - --nginx-configmap=nginx-ingress/nginx-ingress-controller
```

## Deploying Kube-Lego

[Kube-Lego](https://github.com/jetstack/kube-lego) automatically requests certificates for Kubernetes Ingress resources from Let's Encrypt.

It recognizes the need of a new certificate, then it creates a user account (incl. private key) for Let's Encrypt and stores it in Kubernetes secrets. It obtains certificates from Let's Encrypt and authorizes the request with the HTTP-01 challenge. It makes sure that the specific Kubernetes objects (Services, Ingress) are configured for the HTTP-01 challenge to succeed.

As soon as the kube-lego daemon is running, it will create a user account with LetsEncrypt, make a service resource, and look for ingress resources that have this annotation:

```yaml
metadata:
  annotations:
    kubernetes.io/tls-acme: "true"
```

#### Let's deploy Kube-Lego

```yaml
# The only changes necessary are in the data section of the 
# configmap below.
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-lego
  namespace: nginx-ingress
data:
  # modify this to specify your address
  lego.email: ""
  # configure letencrypt's production api
  lego.url: "https://acme-v01.api.letsencrypt.org/directory"
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kube-lego
  namespace: nginx-ingress
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: kube-lego
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: kube-lego
        image: jetstack/kube-lego:0.1.3
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: LEGO_EMAIL
          valueFrom:
            configMapKeyRef:
              name: kube-lego
              key: lego.email
        - name: LEGO_URL
          valueFrom:
            configMapKeyRef:
              name: kube-lego
              key: lego.url
        - name: LEGO_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LEGO_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 1

```

Now if the domain is pointed is pointed to the loadbalancer and the loadbalancer is pointed to the GKE nodes we should be able to deploy a service in any namespace that will automatically have Let's Encrypt TLS encryption.  We would just need to create a CNAME for the service such as 'echoserver.mydomain.com'

### Load balancer

Here's how to setup the load balancer and health check:
  
Note: The firewall rules need to allow port 80 and 443 to reach each of the kubernetes nodes from the load balancer.

To make a TCP loadbalancer go to `Networking -> Load Balancing` in the menu. Select the middle (TCP Load Balancing)

![start](https://raw.githubusercontent.com/dstroot/k8s-resources/master/nginx-ingress-acme-oauth2/img/start.png)

Setup the back end (basically you want to point to your whole GKE cluster):

![backend](https://raw.githubusercontent.com/dstroot/k8s-resources/master/nginx-ingress-acme-oauth2/img/backend.png)

Setup the front end (basically point your IP to port 80 and 443).  You should of course use a static IP address which can reserve with `Networking -> External IP addresses`:
  
![frontend](https://raw.githubusercontent.com/dstroot/k8s-resources/master/nginx-ingress-acme-oauth2/img/frontend.png)

NOTE: Point your DNS/CNAME to the static IP above.

Here is the health check (use HTTP 80 to ping /healthz):

![health](https://raw.githubusercontent.com/dstroot/k8s-resources/master/nginx-ingress-acme-oauth2/img/health.png)

### Example using a simple echo server

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: echoserver
---
apiVersion: v1
kind: Service
metadata:
  name: echoserver
  namespace: echoserver
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: echoserver
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: echoserver
  namespace: echoserver
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: echoserver
    spec:
      containers:
      - image: gcr.io/google_containers/echoserver:1.0
        imagePullPolicy: Always
        name: echoserver
        ports:
        - containerPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echoserver
  namespace: echoserver
  # The annotations below make the magic happen
  # GKE has a native ingress controller, so to *not* use the native one:
  #  Set the annotation `kubernetes.io/ingress.class: "nginx"`
  #  Set the annotation `kubernetes.io/tls-acme: "true"` for automatic TLS
  annotations:
    kubernetes.io/tls-acme: "true"
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  # Setup a CNAME to point to the LB IP address
  - hosts:
    - echoserver.thepishoppe.com
    secretName: echoserver-tls
  rules:
  - host: echoserver.thepishoppe.com
    http:
      paths:
      - path: /
        backend:
          serviceName: echoserver
          servicePort: 80
```

### Adding OAUTH2 authentication

Now we can get really creative and add in OAUTH2 authentication using Bitly's
[oauth2-proxy](https://github.com/bitly/oauth2_proxy).  We will simply add another container into our pod to handle the authentication.  So now we will have automatic TLS and authentication!  

This requires setting up an authentication provider - see Bitly's instructions. Here is a simple example:

![OAuth2 Proxy Architecture](https://cloud.githubusercontent.com/assets/45028/8027702/bd040b7a-0d6a-11e5-85b9-f8d953d04f39.png)

![Github Example](https://raw.githubusercontent.com/dstroot/k8s-resources/master/nginx-ingress-acme-oauth2/img/OAuth_Application_Settings.png)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: echoserver
---
apiVersion: v1
kind: Service
metadata:
  name: echoserver
  namespace: echoserver
spec:
  ports:
  - port: 8080
    # target port will be the oauth2_proxy port
    targetPort: 4180
    protocol: TCP
  selector:
    app: echoserver
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: echoserver
  namespace: echoserver
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: echoserver
    spec:
      containers:
      - name: echoserver
        image: gcr.io/google_containers/echoserver:1.0
        # imagePullPolicy: Always
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 50m
            memory: 100Mi
        ports:
        # the port the service really runs on
        - containerPort: 8080
      # The oauth2-proxy will point to our ultimate destination
      # https://github.com/bitly/oauth2_proxy
      - name: oauth2-proxy
        image: a5huynh/oauth2_proxy
        # imagePullPolicy: Always
    
        # The GitHub auth provider supports two additional parameters to restrict 
        # authentication to Organization or Team level access. Restricting by 
        # org and team is normally accompanied with --email-domain=*
        # -github-org="": restrict logins to members of this organisation
        # -github-team="": restrict logins to members of any of these teams, separated by a comma
        args:
          - "-upstream=http://localhost:8080/"
          - "-provider=github"
          - "-cookie-secure=true"
          - "-cookie-expire=168h0m"
          - "-cookie-refresh=60m"
          - "-cookie-secret=__SECRET__"
          - "-cookie-domain=echo.thepishoppe.com"
          - "-http-address=0.0.0.0:4180"
          - "-redirect-url=https://echo.thepishoppe.com/oauth2/callback"
          - "-email-domain=*"
          - "-client-id=__ID__"
          - "-client-secret=__ID SECRET__"
        ports:
        - containerPort: 4180
---
# Ingress listens on port 443 and listens for "echo.thepishoppe.com" 
# which points to the service "echoserver". The annotations tell the 
# NGINX and Kube Lego services to get a Let's encrypt certificate.
# Ingress on 443 -> Service 8080 -> OAUTH2 Proxy 4180 -> Echo Server 8080
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echoserver
  namespace: echoserver
  annotations:
    kubernetes.io/tls-acme: "true"
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  - hosts:
    - echo.thepishoppe.com
    secretName: echo-tls
  rules:
  - host: echo.thepishoppe.com
    http:
      paths:
      - path: /
        backend:
          serviceName: echoserver
          servicePort: 8080
```

Resources:

* https://github.com/kubernetes/ingress
* https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx
* https://github.com/kubernetes/ingress/tree/master/examples/external-auth/nginx
* https://eng.fromatob.com/post/2017/02/lets-encrypt-oauth-2-and-kubernetes-ingress/
* https://github.com/fromAtoB/manifests/tree/master/nginx-ingress