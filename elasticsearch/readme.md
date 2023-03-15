By default when a Kubernetes cluster is created for the Google Compute Platform a pod is scheduled to execute on each node to gather all the Docker container log files using the Fluentd log collector. This is configured to send the collected log files to Elasticsearch although an instance of Elasticsearch is not created -- this should be done by the user (as we shall demonstrate). It is also possible to configure the cluster to target Google’s Cloud Logging service.

The container kubernetes/fluentd-elasticsearch is constantly looking at the logs files of Docker containers in the directories /var/lib/docker/containers/* and sending (tailing) this information in Logstash format to port 9200 on the local node.

References

http://blog.raintown.org/2014/11/logging-kubernetes-pods-using-fluentd.html?m=1


https://hub.docker.com/_/elasticsearch/

https://blog.treasuredata.com/blog/2016/08/03/distributed-logging-architecture-in-the-container-era/
