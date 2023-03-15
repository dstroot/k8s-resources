Etcd requires a two step deployment.  

First, we will deploy the etcd operator from CoreOS, then we will update the configuration to create a cluster.  

https://github.com/kubernetes/charts/tree/master/stable/etcd-operator
https://github.com/coreos/etcd-operator


```
~/Code/k8s-resources/helm/etcd master*
❯ helm install stable/etcd-operator --name etcd
NAME:   etcd
LAST DEPLOYED: Sun Jul  2 18:19:09 2017
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Deployment
NAME                DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
etcd-etcd-operator  1        1        1           0          0s


NOTES:
1. etcd-operator deployed.
  If you would like to deploy an etcd-cluster set cluster.enabled to true in values.yaml
  Check the etcd-operator logs
    export POD=$(kubectl get pods -l app=etcd-etcd-operator --namespace default --output name)
    kubectl logs $POD --namespace=default

~/Code/k8s-resources/helm/etcd master*
❯ helm upgrade -f overridevalues.yaml etcd stable/etcd-operator
Release "etcd" has been upgraded. Happy Helming!
LAST DEPLOYED: Sun Jul  2 18:24:09 2017
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Deployment
NAME                DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
etcd-etcd-operator  1        1        1           1          5m

==> v1beta1/Cluster
NAME          KIND
etcd-cluster  Cluster.v1beta1.etcd.coreos.com


NOTES:
1. Watch etcd cluster start
  kubectl get pods -l etcd_cluster=etcd-cluster --namespace default -w
2. Confirm etcd cluster is healthy
  $ kubectl run --rm -i --tty --env="ETCDCTL_API=3" --env="ETCDCTL_ENDPOINTS=http://etcd-cluster-client:2379" etcd-test --image quay.io/coreos/etcd --restart=Never -- /bin/sh -c 'watch -n1 "etcdctl  member list"'

3. Interact with the cluster!
  $ kubectl run --rm -i --tty --env ETCDCTL_API=3 etcd-test --image quay.io/coreos/etcd --restart=Never -- /bin/sh
  / # etcdctl --endpoints http://etcd-cluster-client:2379 put foo bar
  / # etcdctl --endpoints http://etcd-cluster-client:2379 get foo
  OK
  (ctrl-D to exit)
4. Optional
  Check the etcd-operator logs
  export POD=$(kubectl get pods -l app=etcd-etcd-operator --namespace default --output name)
  kubectl logs $POD --namespace=default

~/Code/k8s-resources/helm/etcd master*
❯
```
