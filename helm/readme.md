Helm repository for your Kubernetes cluster
-------------------------------------------

Helm is the Kubernetes package manager. It lets you define, install and manage applications on your Kubernetes cluster.  You can setup and start using Helm, very quickly on an existing Kubernetes cluster. Think of it like apt/yum/homebrew for Kubernetes.

* Helm has two parts: a client (helm) and a server (tiller)
* Tiller runs inside of your Kubernetes cluster, and manages releases (installations) of your charts.
* Helm runs on your laptop, CI/CD, or wherever you want it to run.
* Charts are Helm packages that contain at least two things:
  1. A description of the package (Chart.yaml)
  2. One or more templates, which contain Kubernetes manifest files
* Charts can be stored on disk, or fetched from remote chart repositories (like Debian or RedHat packages)

However, like any other package manager, Helm needs a repository to pull installation files. By default this is called the stable repository and is located at https://kubernetes-charts.storage.googleapis.com. For users who’d like to host their own Helm repository, there is a Helm command to do so : `helm repo add`.

An object store is a perfect place to keep such a data repository. So something like:
* AWS S3
* GCP Storage 
* Minio
* Others...

### Install Helm

Prerequisites: Kubernetes cluster with `kubectl` configured to point to the cluster.  When you execute helm for the first time, it picks your Kubernetes cluster info from the default location `$HOME/.kube/config`. So, it knows which cluster to talk to and how to authenticate itself.  That is why you need a Kubernetes clusters and a working setup of `kubectl`. To find out which cluster Tiller would install to, you can run `kubectl config current-context` or `kubectl cluster-info`.

First, [download and install the Helm CLI](https://github.com/kubernetes/helm#install) on your computer.

Next, run `helm init` to install the Helm server component (Tiller). This will install Tiller into the Kubernetes cluster you saw with `kubectl config current-context`.

TIP: Want to install into a different cluster? Use the `--kube-context` flag.

TIP: When you want to upgrade Tiller, just run `helm init --upgrade`.

TIP: [Helm Docs](https://docs.helm.sh/using_helm/#quickstart-guide)

### Test Helm installation

Let's get the latest stable version of charts with `helm repo update`

```
❯ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

### Create a remote helm repository

I used GCP: [Google Cloud Storage](https://github.com/kubernetes/helm/blob/master/docs/chart_repository.md#google-cloud-storage)

Make sure your bucket is public:

![alt text](https://bytebucket.org/dstroot/k8s-resources/raw/d2fe69b813f5411dda5aff8de6d6912381e4e098/helm/permissions.png?token=a780e753f949135640e4b7dbbdaeee4d78fa6a55 "Permissions")


Note: A public GCS bucket can be accessed via simple HTTPS at this address: `https://bucket-name.storage.googleapis.com/`.

TIP: Set [object versioning](https://cloud.google.com/storage/docs/gsutil/addlhelp/ObjectVersioningandConcurrencyControl#top_of_page) on your GCS bucket in case you accidentally delete somethin

```
❯ gsutil versioning set on gs://bruinboi_helm/
Enabling versioning for gs://bruinboi_helm/...
```

TIP: Use the gsutil rsync functionality to [sync a local dir to a GCP bucket](https://github.com/kubernetes/helm/blob/master/docs/chart_repository_sync_example.md#sync-your-local-and-remote-chart-repositories)


### Add this repository as your chart repo:

```
helm repo add myrepo https://bruinboi_helm.storage.googleapis.com/
```

### Test your repository

Now that everything is set, let’s test if Helm can talk to your new repository and install applications to the Kubernetes cluster.

```
helm install myrepo/minio
```

If everything went well, you’ll see helm setting up a new release based on the minio chart.

#### Resources

https://blog.minio.io/minio-as-helm-repository-for-your-kubernetes-cluster-9b2dcc771ee5
https://github.com/kubernetes/helm/blob/master/docs/using_helm.md





