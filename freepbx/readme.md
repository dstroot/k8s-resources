To get terminal access inside the container:

`kubectl exec -ti freepbx-1811234425-43n08 -- bash`

execs bash with an interactive terminal (-ti) in specified container (pod)

`echo "$(minikube ip) freepbx.local" | sudo tee -a /etc/hosts`