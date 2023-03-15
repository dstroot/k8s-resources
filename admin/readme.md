Docker File: https://github.com/grafana/grafana-docker
Docker Hub: https://hub.docker.com/r/grafana/grafana/
Github: https://github.com/grafana/grafana


Configuring grafana
https://github.com/grafana/grafana/blob/master/conf/sample.ini


Point it at your external prometheus endpoint.  




`kubectl create secret generic grafana-secret --from-file=./user.txt --from-file=./password.txt`
