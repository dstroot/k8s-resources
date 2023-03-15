# Grafana

This will install Grafana and connect it with Prometheus to monitor all aspects of the cluster.  

### Steps

1. Create an Admin account name and password and load them into a Kubernetes secret: `kubectl create secret generic grafana-secret --from-file=./user.txt --from-file=./password.txt --namespace='monitoring'`
2. Install Grafana: `kubectl create -f grafana.yml`.
3. Port-forward Grafana to your local machine: `kubectl port-forward grafana-yourpod-name 3000:3000 --namespace='monitoring'`.  Go to `http://localhost:3000` and you should see the Grafana UI.
4. Create the Prometheus datasource and load up some dashboards. The first option under "Loading the datasource and dashboards automatically" I think is the simplest.

RBAC Notes:

For reference, I was able to resolve the new 1.6 RBAC reqirements by giving it "god" mode: `kubectl create clusterrolebinding add-on-cluster-admin-monitoring --clusterrole=cluster-admin --serviceaccount=monitoring:default` 
This is not a long term solution but it will work as a hack for now. 

#### To Do

* [ ] Use OAuth/2 Authentication

## Prometheus Datasource

- Configure [Prometheus](https://grafana.net/plugins/prometheus) data source for Grafana.<br/>
`Grafana UI / Data Sources / Add data source`
  - Name:    `prometheus`
  - Type:    `Prometheus`
  - Url:     `http://prometheus:9090`
  - Access:  `proxy`
  - Save & Test

## More Dashboards

See grafana.net for some example [dashboards](https://grafana.net/dashboards) and [plugins](https://grafana.net/plugins).

- Import [Prometheus Stats](https://grafana.net/dashboards/2):<br/>
  `Grafana UI / Dashboards / Import`
  - Grafana.net Dashboard: `https://grafana.net/dashboards/2`
  - Load
  - Prometheus: `prometheus`
  - Save & Open

- Import [Kubernetes Cluster Monitoring](https://grafana.net/dashboards/162):<br/>
  `Grafana UI / Dashboards / Import`
  - Grafana.net Dashboard: `https://grafana.net/dashboards/162`
  - Load
  - Prometheus: `prometheus`
  - Save & Open
  
- Import [Kubernetes Node Monitoring](https://grafana.com/dashboards/718):<br/>
  `Grafana UI / Dashboards / Import`
  - Grafana.net Dashboard: `https://grafana.com/dashboards/718`
  - Load
  - Prometheus: `prometheus`
  - Save & Open

## Loading the datasource and dashboards automatically

1. The simplest method is to port-forward the Grafana pod to your local machine using: `kubectl port-forward grafana-your-podname 3000:3000 --namespace='monitoring'`
  - NOTE: [create an API key](http://docs.grafana.org/http_api/auth/) in UI first! Then update the `./load-config.sh` with the API Key. Then from the `configs` directory run the script: `./load-config.sh`. This will create the Prometheus datasource automatically and load the Kubernetes and Prometheus dashboards.  
  - NOTE: you will need [jq](https://stedolan.github.io/jq/) and [curl](https://curl.haxx.se/) installed locally.  
2. The other method involves loading the configuration .json files into a Kubernetes configMap and then running a job inside the cluster to read the configs from the configMap and call the Grafana API within the cluster.
  - First, create the configMap: `kubectl create configmap grafana-config --from-file=configs --namespace='monitoring'`. This should load the whole `configs` directory into the configMap.
  - Then create the job to load the configs: `kubectl create -f load-configs-job.yml`. The job should load the configuration into Grafana and complete. To clean up you can delete the configMap and the job as they are no longer needed.
  
#### Resources

* [Grafana Website](https://grafana.com/)
* [Giant Swarm's Setup - Good](https://github.com/giantswarm/kubernetes-prometheus)
* [CoreOS Prometheus Operator](https://coreos.com/blog/the-prometheus-operator.html)
* [Docker File](https://github.com/grafana/grafana-docker)
* [Docker Hub](https://hub.docker.com/r/grafana/grafana/)
* [Github](https://github.com/grafana/grafana)
* [Grafana Configuration](https://github.com/grafana/grafana/blob/master/conf/sample.ini)
  