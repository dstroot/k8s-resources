### Namespaces

Namespaces logically organize your system.  Kubernetes namespaces help different projects, teams, or customers to share a Kubernetes cluster. It does this by providing the following:
* A scope for Names.
* A mechanism to attach authorization and policy to a subsection of the cluster.

Examples

* monitoring - for all monitoring components (e.g. prometheus, prometheus scrapers, grafana, etc.)
* kube-system - kubernetes system components
* production - all production resources
* non-production - all Non-Production resources (e.g. testing, playing around, development, etc.)

### Labels

Labels are the domain of users. They are intended to facilitate organization and management of resources using attributes that are meaningful to users, as opposed to meaningful to the system. Think of them as user-created tags.  Labels are used for semantic meaning.  This will let you select the object groups appropriate to the context— e.g., a service for all “tier: frontend” pods, or all “test” phase components of app “myapp”. 

* app: myapp, 
* tier: frontend, backend
* phase: test, prod
* version: v2, v3



[Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
[Namespaces](https://kubernetes.io/docs/admin/namespaces/walkthrough/)
https://www.ianlewis.org/en/using-kubernetes-namespaces-manage-environments
https://www.projectcalico.org/securing-namespaces-and-services-in-kubernetes/

