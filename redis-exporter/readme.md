https://hub.docker.com/r/21zoo/redis_exporter/
https://github.com/oliver006/redis_exporter


Add a block to the scrape_configs of your prometheus.yml config file:

```
# Scrape Redis Exporter
- job_name: 'redis_exporter'
  static_configs:
  - targets: ['redis-exporter:9121']
```
