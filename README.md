# k8s-resources

## A TypicaL Journey

#### No Containers

You begin with an "old school" business.  Let's say we have a PostgreSQL database cluster and a Redis cluster and various applications, reporting tools, and web properties interacting with these clusters.  You're not a bright shiny startup, but an existing business that has been around for while and you have a lot of legacy "stuff".

#### Some Containers

You discover Docker and start containerizing.  You find that once you learn how to put your web applications in containers it gives you automatic restarts, easier deployments and more consistency across environments.  You decide containers are cool and start containerizing other things.

So far though, these containers work by leveraging your *existing infrastructure* - they can access your storage, they leverage your DNS to find your database and Redis server(s), etc.  You think to yourself - this is awesome!  It becomes trivially easy for your QA team to spin up a machine pointing to the QA database, run tests and spin it down - they just need to learn some Docker commands.

#### Lots of Containers

But it's getting harder to manage all your containers.  You need/want something to place containers on hosts for you, you want to manage rolling updates, load balancing and scaling become concerns and you discover Kubernetes.  "Aha" you say!  My troubles are over!  I am going to manage my containers using Kubernetes.

You don't really consider containerizing/moving your legacy data stores (they sit on special hardware and storage) and you have some legacy stuff you don't want to touch, but you think an architecture like this seems pretty reasonable:

```
+--------------------+       +-------------+       +-------------+
|                    |       |             |       |             |
|     Kubernetes     |<----->|  PostgreSQL |<----->|   Legacy    |
|                    |       |             |       |             |
|                    |       +-------------+       +-------------+
|                    |                               /            
|                    |       +-------------+        /
|                    |       |             |       /
|                    |<----->|    Redis    |<-----/
|                    |       |             |
+--------------------+       +-------------+
```

#### Challenges (Kubernetes 1.3)

* You discover anything inside Kubernetes has its own DNS and cannot "see" anything outside of Kubernetes
* Your containers that were trivially easy to run outside of Kubernetes, cannot see or access your PostgreSQL or Redis production systems from inside Kubernetes.
* You might consider moving Redis inside Kubernetes (but not PostgreSQL yet), however you find that Redis clustering, sentinels, etc. don't exactly fit how Kubernetes works.  There are many examples of how to run Redis inside Kubernetes none seem to be truly a full production-level example. Pet Sets are brand new.

### Kubernetes Notes 

[Kubernetes Networking](https://kubernetes.io/docs/user-guide/services/#virtual-ips-and-service-proxies)

[Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

Labels are the domain of users. They are intended to facilitate organization and management of API resources using attributes that are meaningful to users, as opposed to meaningful to the system. Think of them as user-created tags.  

Define and use labels that identify semantic attributes of your application or deployment. For example, instead of attaching a label to a set of pods to explicitly represent some service (e.g., service: myservice), or explicitly representing the replication controller managing the pods (e.g., controller: mycontroller), attach labels that identify semantic attributes, such as { app: myapp, tier: frontend, phase: test, deployment: v3 }. This will let you select the object groups appropriate to the context— e.g., a service for all “tier: frontend” pods, or all “test” phase components of app “myapp”. 

TIP:

You can use [kubeval](https://github.com/garethr/kubeval) to evaluate K8S configuration files locally.  Good for developing locally!

```
~/Code/k8s-resources/freepbx master
❯ kubeval -v 1.6.6 1-freepbx.yml
The document 1-freepbx.yml is not a valid Ingress
--> spec.rules.0.http.paths.0.backend.servicePort: Invalid type. Expected: string, given: integer
```


### Ingress Questions

On GCP, the HTTP load balancers do not currently support TLS-SNI, which means you need a new frontend IP address per SSL certificate you have. For internal services, this is a pain, as you cannot point a wildcard DNS entry to a single IP, like *.mydomain.com and then have everything just work. Using a TCP load balancer with the NGINX Ingress Controller works just as well, and supports TLS-SNI no problem. In addition we can use Kube-Lego to automatically get Let's Encrypt certificates so that helps out a lot as well.

But there are multiple ways to deploy the NGINX Ingress Controller.  In the examples folder there are examples for a daemonset, a deployment without a service and in "/static-ip" there is an example using a service with a static loadbalancer IP. I can't seem to find any guidance about when to use what model (see questions below).

My preferred method is to leverage GCP "the product" as much as possible.  So on GCP I can create a deployment with two replicas (for rolling updates, redundancy, etc.) and a service with a "LoadBalancer" and a "loadBalancerIP" static IP (that I have already reserved) and the platform will create an external loadbalancer, create the external firewall rules, and point them to my internal K8S service, which points to my deployment. It seems to work just fine and therefore I don't have to manually setup a loadbalancer and firewall rules. My configuration is below.

### MY QUESTIONS
* can anyone give advice why *not* to do it this way?  Why use a daemonset for example, or a deployment without a service?
* Why are all the examples mapping hostPort's? The [Kubernetes Overview](https://kubernetes.io/docs/concepts/configuration/overview/) says: "Don’t use hostPort (which specifies the port number to expose on the host) unless absolutely necessary, e.g., for a node daemon. When you bind a Pod to a hostPort, there are a limited number of places that pod can be scheduled, due to port conflicts— you can only schedule as many such Pods as there are nodes in your Kubernetes cluster."


```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller
  namespace: nginx-ingress
  labels:
    app: nginx-ingress-controller
  annotations: 
    service.beta.kubernetes.io/external-traffic: "OnlyLocal"
spec:
  type: LoadBalancer
  loadBalancerIP: 1.1.1.1
  ports:
    - port: 80
      name: http
      targetPort: 80
    - port: 443
      name: https
      targetPort: 443
  selector:
    k8s-app: nginx-ingress-controller
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: nginx-ingress
  labels:
    k8s-app: nginx-ingress-controller
  annotations:
    prometheus.io/port: "10254"
    prometheus.io/scrape: "true"
spec:
  replicas: 2
  template:
    metadata:
      labels:
        k8s-app: nginx-ingress-controller
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: nginx-ingress-controller
        image: gcr.io/google_containers/nginx-ingress-controller:0.9.0-beta.3
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
          initialDelaySeconds: 10
          timeoutSeconds: 1
        ports:
        - name: http
          containerPort: 80
          # hostPort: 80  << Why?
        - name: https
          containerPort: 443
          # hostPort: 443 << Why?
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        args:
        - /nginx-ingress-controller
        - --default-backend-service=$(POD_NAMESPACE)/default-http-backend
        - --publish-service=$(POD_NAMESPACE)/nginx-ingress-controller
        - --configmap=$(POD_NAMESPACE)/nginx-ingress-controller
```

[Ingress Docs](https://github.com/kubernetes/ingress/tree/master/controllers/nginx#why-endpoints-and-not-services) say: "The NGINX ingress controller does not uses Services to route traffic to the pods. Instead it uses the Endpoints API in order to bypass kube-proxy to allow NGINX features like session affinity and custom load balancing algorithms. It also removes some overhead, such as conntrack entries for iptables DNAT."

The [Kubernetes Overview](https://kubernetes.io/docs/concepts/configuration/overview/) says: "Don’t use hostPort (which specifies the port number to expose on the host) unless absolutely necessary, e.g., for a node daemon. When you bind a Pod to a hostPort, there are a limited number of places that pod can be scheduled, due to port conflicts— you can only schedule as many such Pods as there are nodes in your Kubernetes cluster."


New Cluster Setup
-----------------

0. Clone k8s-resources `git clone https://github.com/dstroot/k8s-resources.git && cd k8s-resources`

1. Setup Namespaces  http://kubernetes.io/docs/admin/namespaces/

   NOTE: Use kubectl create -f <directory> where possible. This looks for config objects in all .yaml, .yml, and .json files in <directory> and passes them to create.

   `kubectl create -f namespaces`

2. Build out backend

   NOTE:
   * It’s typically best to create a service before corresponding replication controllers, so that the scheduler can spread the pods comprising the service.
   * Best practices: http://kubernetes.io/docs/user-guide/config-best-practices/

Information taken from here: https://github.com/kubernetes/kubernetes/tree/master/examples/k8petstore


### Minikube vs GKE

Minikube will configure kubectl for you when you launch it.  How to configure GKE 

To change kubectl itself, simply run the following:

`kubectl config set current-context {context-name}`

So, for example, if you have a local minikube cluster setup, run the following:

`kubectl config set current-context minikube`
And you're kubectl CLI is no working with your local minikube.


Configure kubectl command line access by running the following command:

`gcloud container clusters get-credentials cluster-1 \
    --zone us-west1-b --project splendid-timer-160003`
    
`gcloud container clusters get-credentials cluster-1`

Then start a proxy to connect to the Kubernetes control plane:

`kubectl proxy`

Then open the Dashboard interface by navigating to the following location in your browser:

`http://localhost:8001/ui`


### Redis

Redis is configured via a .conf file.  So when you are building redis containers and you want to tune your configuration you change the .conf and rebuild the container. So the docker file would look like this:

```
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Redis Dockerfile
#
# https://github.com/dockerfile/redis
#

# Pull base image.
#
# Just a stub.

FROM redis

ADD etc_redis_redis.conf /etc/redis/redis.conf

CMD ["redis-server", "/etc/redis/redis.conf"]
# Expose ports.
EXPOSE 6379
```

and the redis.conf file would be:

```
pidfile /var/run/redis.pid
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 0
loglevel verbose
syslog-enabled yes
databases 1
save 1 1
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression no
rdbchecksum yes
dbfilename dump.rdb
dir /data
slave-serve-stale-data no
slave-read-only yes
repl-disable-tcp-nodelay no
slave-priority 100
maxmemory <bytes>
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 1
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events "KEg$lshzxeA"
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
```

### [Kubernetes kubectl Tips and Tricks](https://coreos.com/blog/kubectl-tips-and-tricks)

[kubectl Cheat Sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/)

Create a base 64 encoded 32 byte secret from the shell:

`head -c 32 /dev/urandom | base64 -i - -o -`

```
❯ head -c 32 /dev/urandom | base64 -i - -o -
C6PZ99G1hfzIjfCzdxWZPhlc//AQpaMGkovkffI/mQs=

~
❯
```
