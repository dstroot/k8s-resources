Prometheus is a whitebox monitoring system, ingesting metrics exposed from *inside* applications. Sometimes though you want to check how things look from the outside, which is to say blackbox monitoring. For this Prometheus offers the blackbox_exporter. The blackbox_exporter allows for a variety of network checks to be performed, with many common modules available out of the box. The blackbox exporter allows blackbox probing of endpoints over HTTP, HTTPS, TCP and ICMP.

#### Resources

* https://www.robustperception.io/checking-if-ssh-is-responding-with-prometheus/
* https://quay.io/repository/prometheus/blackbox-exporter
* https://michael.stapelberg.de/Artikel/prometheus-blackbox-exporter
* https://github.com/prometheus/blackbox_exporter
