# Ghost Recipe

So you want to setup a nice new blog with a streamlined development workflow? If you want a simple, back-to-basics blogging platform, then Ghost is a good choice. This recipe shows how to deploy Ghost using Kubernetes and Docker.

### Kubernetes Versions

Tested on Versions: 1.3.2, 1.3.3, 1.3.4

## Ingredients

Recommendations:
* When available we prefer the use of official images
* Always use specified versions
* Use the smallest image possible (generally the alpine variant if avaialable)

Official Image: [Ghost](https://hub.docker.com/_/ghost/)

## Preparation

##### Table of Contents

 * [Step Zero: Prerequisites](#step-zero)
 * [Step One: Setup a data volme](#step-one)
 * [Step Two: Create a Ghost ConfigMap](#step-two)
 * [Step Three: Create a Ghost service](#step-three)
 * [Step four: Create a Ghost deployment](#step-four)
 * [Step Seven: View the guestbook](#step-seven)
 * [Step Eight: Cleanup](#step-eight)

### Step Zero: Prerequisites <a id="step-zero"></a>

This recipe assumes that you have a Kubernetes cluster installed and running, and that you have installed the `kubectl` command line tool somewhere in your path.  See the [Getting Started Guides](../../docs/getting-started-guides/) for details about creating a cluster.

You can also test this using `minikube` if you have it installed locally.

**Tip:** View all the `kubectl` commands, including their options and descriptions in the [kubectl CLI reference](../../docs/user-guide/kubectl/kubectl.md).

### Step One: Setup a data volome <a id="step-one"></a>

We will need some persistent disk to contain our blog content. We do not want to lose our content if our container restarts!  Covering all the variations of how to do this is outside the scope of this recipe.  This example shows how to do it on the Google Cloud Platform.

[gcloud](https://cloud.google.com/sdk/docs/) is a tool that provides the primary command-line interface to Google Cloud Platform. You can use this tool to perform many common platform tasks either from the command-line, or in scripts and other automations. Use `gloud` to create a volume:

```shell
$ gcloud compute disks create --size 200GB ghost
Created [https://www.googleapis.com/compute/v1/projects/theta-dialect-137923/zones/us-central1-b/disks/ghost].
NAME    ZONE           SIZE_GB  TYPE         STATUS
ghost   us-central1-b  200      pd-standard  READY
```

### Step Two: Create a Ghost ConfigMap <a id="step-two"></a>

Ghost uses a `config.js` file for configuration. We will use a Kubernetes ConfigMap to hold a special version of a `config.js` file that will be mounted into the Docker container.  Because we want things to be dynamic we have written the `config.js` file to pick up environment variables from the container.  In this way we can just configure Ghost using environment variables and avoid editing `config.js`.  If no environment variables are set Ghost will run in a default development configuration.   

1. Use the [0-ghost-config.yaml](0-ghost-config.yaml) file to create the Ghost configMap in your Kubernetes cluster by running the `kubectl create -f` *`filename`* command:

    ```console
    $ kubectl create -f 0-ghost-config.yaml
    ```

    Result: A configMap named "ghost" will be created so it can later be mounted into the Ghost Docker container.

### Step Three: Create a Ghost service <a id="step-three"></a>

We will deploy Ghost by creating a Kubernetes service and a deployment. **NOTE:** You will have to adjust the environment variable values in the .yaml file before launch.  

1. Use the file [1-ghost-service.yaml](1-ghost-service.yaml) to create the ghost service by running the `kubectl create -f` *`filename`* command:

    ```console
    $ kubectl create -f examples/guestbook-go/redis-slave-controller.json
    replicationcontrollers/redis-slave
    ```

    This is the contents of the `1-ghost-service.yaml` file:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: ghost
      labels:
        app: ghost
    spec:
      selector:
        app: ghost
      type: LoadBalancer
      ports:
      - port: 80
        targetPort: ghost
        protocol: TCP
    ```

    Result: The service is created with labels `app=ghost` to identify that the pods are running Ghost.  It will make a load balanced service available using all pods with that label.



2. To verify that the redis-slave controller is running, run the `kubectl get rc` command:

    ```console
    $ kubectl get rc
    CONTROLLER              CONTAINER(S)            IMAGE(S)                         SELECTOR                    REPLICAS
    redis-master            redis-master            redis                            app=redis,role=master       1
    redis-slave             redis-slave             kubernetes/redis-slave:v2        app=redis,role=slave        2
    ...
    ```

    Result: The replication controller creates and configures the Redis slave pods through the redis-master service (name:port pair, in our example that's `redis-master:6379`).





2. To verify that the redis-slave service is up, list the services you created in the cluster with the `kubectl get services` command:

    ```console
    $ kubectl get services
    NAME              CLUSTER_IP       EXTERNAL_IP       PORT(S)       SELECTOR               AGE
    redis-master      10.0.136.3       <none>            6379/TCP      app=redis,role=master  1h
    redis-slave       10.0.21.92       <none>            6379/TCP      app-redis,role=slave   1h
    ...
    ```

    Result: The service is created with labels `app=redis` and `role=slave` to identify that the pods are running the Redis slaves.

Tip: It is helpful to set labels on your services themselves--as we've done here--to make it easy to locate them later.



### Step Seven: View the guestbook <a id="step-seven"></a>

You can now play with the guestbook that you just created by opening it in a browser (it might take a few moments for the guestbook to come up).

 * **Local Host:**
    If you are running Kubernetes locally, to view the guestbook, navigate to `http://localhost:3000` in your browser.

 * **Remote Host:**
    1. To view the guestbook on a remote host, locate the external IP of the load balancer in the **IP** column of the `kubectl get services` output. In our example, the internal IP address is `10.0.217.218` and the external IP address is `146.148.81.8` (*Note: you might need to scroll to see the IP column*).

    2. Append port `3000` to the IP address (for example `http://146.148.81.8:3000`), and then navigate to that address in your browser.

    Result: The guestbook displays in your browser:

    ![Guestbook](guestbook-page.png)

    **Further Reading:**
    If you're using Google Compute Engine, see the details about limiting traffic to specific sources at [Google Compute Engine firewall documentation][gce-firewall-docs].

[cloud-console]: https://console.developer.google.com
[gce-firewall-docs]: https://cloud.google.com/compute/docs/networking#firewalls

### Step Eight: Cleanup <a id="step-eight"></a>

After you're done playing with the guestbook, you can cleanup by deleting the guestbook service and removing the associated resources that were created, including load balancers, forwarding rules, target pools, and Kubernetes replication controllers and services.

Delete all the resources by running the following `kubectl delete -f` *`filename`* command:

```console
$ kubectl delete -f examples/guestbook-go
guestbook-controller
guestbook
redid-master-controller
redis-master
redis-slave-controller
redis-slave
```


```console
2016-08-20T14:04:43.193898245Z npm info it worked if it ends with ok
2016-08-20T14:04:43.194498843Z npm info using npm@2.15.8
2016-08-20T14:04:43.194890475Z npm info using node@v4.4.7
2016-08-20T14:04:43.448797411Z npm info prestart ghost@0.9.0
2016-08-20T14:04:43.453604818Z npm info start ghost@0.9.0
2016-08-20T14:04:43.456022448Z
2016-08-20T14:04:43.456036326Z > ghost@0.9.0 start /usr/src/ghost
2016-08-20T14:04:43.456040462Z > node index
2016-08-20T14:04:43.456043041Z
2016-08-20T14:04:43.557252192Z Starting Ghost using dynamic config...
2016-08-20T14:04:45.285795404Z Ghost is running in production...
2016-08-20T14:04:45.285838378Z Your blog is now available on http://example.com
2016-08-20T14:04:45.285842492Z Ctrl+C to shut down
```


#### Notes

You can install themes by deleting the ghost deployment, starting another container and mounting the ghost disk into the container with git installed and use git to clone other themes into the themes directory: `/var/lib/ghost/content/themes`

example command:
`$ git clone https://github.com/oswaldoacauan/ghostium/ "ghostium"`




WARNING: Ghost is attempting to use a direct method to send email.
It is recommended that you explicitly configure an email service.
Help and documentation can be found at http://support.ghost.org/mail.


#### References

* [Ghost Blogging Platform](https://ghost.org/)
* [Ghost Source Code](https://github.com/TryGhost/Ghost)
* [Official Ghost Docker Image](https://github.com/docker-library/ghost)

http://support.ghost.org/config/
http://coderunner.io/hello-blog-an-advanced-setup-of-ghost-and-docker-made-simple/
