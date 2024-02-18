
ls production/patches.1.28
	kube-system.configmap.coredns.yaml                                     observability.service.kube-prom-stack-kube-prome-alertmanager.yaml
	observability.daemonset.kube-prom-stack-prometheus-node-exporter.yaml  observability.service.kube-prom-stack-kube-prome-prometheus.yaml
	observability.deployment.kube-prom-stack-grafana.yaml                  observability.servicemonitor.kube-prom-stack-grafana.yaml
	observability.prometheus.kube-prom-stack-kube-prome-prometheus.yaml    observability.servicemonitor.kube-prom-stack-kube-prome-coredns.yaml
	observability.service.kube-prom-stack-grafana.yaml

# patch CRD to pull in 'additional-configs.yaml' (from secret 'config-map')
cat production/patches.1.28/observability.prometheus.kube-prom-stack-kube-prome-prometheus.yaml
	spec:
	  additionalScrapeConfigs:
	    key: additional-configs.yaml
	    name: additional-configs
	    optional: true
	  configMaps:
	    - additional-targets
	  retention: 170h

ls apps/prometheus/
	20.ServiceAccount.yml  30.ClusterRole.yml  40.ClusterRoleBinding.yml  50.Secret.yml  60.ConfigMap.yml

# configure 'secret' with contents of 'additional-configs.yaml' and 'additional-targets' configMap with contents of 'http-targets.json'
#   'additional-configs.yaml' contains extra job configs for prometheus
#   'http-targets.json' contains extra prometheus targets for 'job_name: "http-configs"' in 'additional-configs.yaml' to scrape
yaml2json apps/prometheus/50.Secret.yml | jq -r '.data."additional-configs.yaml"' | base64 -d
	- job_name: "http-configs"
	  scrape_interval: 60s
	  scheme: http
	  metrics_path: "/metrics"
	  file_sd_configs:
	    - files:
		- "/etc/prometheus/configmaps/additional-targets/http-targets.json"
	  relabel_configs:
	    - action: replace
	      source_labels: [__address__]
	      target_label: instance
	      regex: '([^:]+)(:[0-9]+)?'
	      replacement: '${1}'
	- job_name: 'zookeeper-exporter'
	  dns_sd_configs:
	    - names:
		- 's3.ubuntu.home'
		- 's7.ubuntu.home'
		- 's8.ubuntu.home'
	      type: 'A'
	      port: 7202
	  relabel_configs:
	    - action: replace
	      source_labels: [__address__]
	      target_label: hostname
	      regex: '([^:]+)(:[0-9]+)?'
	      replacement: '${1}'
	    - action: replace
	      source_labels: [__meta_dns_name]
	      target_label: instance
	    - action: replace
	      source_labels: [__meta_dns_name]
	      target_label: instance
	- job_name: 'kafka-exporter'
	  dns_sd_configs:
	    - names:
		- 's3.ubuntu.home'
		- 's7.ubuntu.home'
		- 's8.ubuntu.home'
	      type: 'A'
	      port: 7204
	  relabel_configs:
	    - action: replace
	      source_labels: [__address__]
	      target_label: hostname
	      regex: '([^:]+)(:[0-9]+)?'
	      replacement: '${1}'
	    - action: replace
	      source_labels: [__meta_dns_name]
	      target_label: instance
	- job_name: minio-job
	  bearer_token: eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjQ4MDY4MjE4NTYsImlzcyI6InByb21ldGhldXMiLCJzdWIiOiJtaW5pb2FkbWluIn0.HtLiGj07teQAS9GYGEPgQ5TU45MgvS0je2ugmOa7EvzaXi54xu4gDpLYoD4XBMeEJthnxD_aU6Yw3EE1BvAxIA
	  metrics_path: /minio/v2/metrics/cluster
	  scheme: http
	  static_configs:
	    - targets: ['s1.ubuntu.home:9000']
	  relabel_configs:
	    - action: replace
	      source_labels: [__address__]
	      target_label: instance
	      regex: '([^:]+)(:[0-9]+)?'
	      replacement: '${1}'

cat apps/prometheus/60.ConfigMap.yml
	apiVersion: v1
	kind: ConfigMap
	metadata:
	  name: additional-targets
	  namespace: observability
	  labels:
	    app.kubernetes.io/component: prometheus
	    app.kubernetes.io/name: prometheus
	    app.kubernetes.io/part-of: kube-prometheus
	    app.kubernetes.io/version: 2.26.0
	    prometheus: k8s
	data:
	  http-targets.json: |-
	    [{"targets":["ballantyne.home:9182"],
	      "labels":{"job":"node-exporter","origin":"windows-nodes"}},
	     {"targets":["nas.home:9100","wdmycloud.home:9100","pi.ubuntu.home:9100","s2.ubuntu.home:9100","s3.ubuntu.home:9100","s4.ubuntu.home:9100"],
	      "labels":{"job":"node-exporter","origin":"unix-nodes"}},
	     {"targets":["s3.ubuntu.home:9999","s7.ubuntu.home:9999","s8.ubuntu.home:9999"],
	      "labels":{"job":"kafka-nodes"}}]
