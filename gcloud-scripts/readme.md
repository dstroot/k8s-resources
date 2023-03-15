# Google Cloud Platform Scripts

[Google Cloud Platform](https://cloud.google.com/)
[Command Line Tool](https://cloud.google.com/sdk/docs/)
[Scripting](https://cloudplatform.googleblog.com/2016/06/filtering-and-formatting-fun-with.html)









## Notes

https://cloud.google.com/sdk/docs/quickstart-mac-os-x



# Redis on GKE

There are a couple settings for Redis that you have to access the underlying
machines to set.  To do so use google cloud console to ssh into each cluster 
machine, then:

```
$ sudo su -
$ sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled
$ sudo nano /etc/rc.local
```

Add the same line above the exit 0 (echo never > /sys/kernel/mm/transparent_hugepage/enabled)

* https://cloud.google.com/solutions/real-time/kubernetes-redis-bigquery#optional_updating_the_startup_scripts_for_long-term_redis_reliability
* http://stackoverflow.com/questions/34141454/sysctl-values-for-google-container-engine-instances
* http://redis.io/topics/admin
* http://serverfault.com/questions/271380/how-can-i-increase-the-value-of-


To set sysctnls for the docker container:


docker 1.12 add support for setting sysctls with --sysctl.

`docker run --name some-redis --sysctl=net.core.somaxconn=511 -d redis`

https://kubernetes.io/docs/concepts/cluster-administration/sysctl-cluster/
https://docs.docker.com/engine/reference/commandline/run/#description


https://cloud.google.com/container-engine/docs/tutorials/http-balancer