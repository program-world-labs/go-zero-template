Name: {{.serviceName}}.rpc
ListenOn: 0.0.0.0:8080
DevServer:
    Enabled: true
Log:
  Stat: false
  Level: debug
  Encoding: plain
Telemetry:
  Name: {{.serviceName}}
  Endpoint: ${LOCAL_ENDPOINT}:4317
  Sampler: 1.0
  Batcher: otlpgrpc
Mode: dev

Env: ${APP_ENV}
Version: ${APP_VERSION}
DataSource:
  Host: ${LOCAL_ENDPOINT}:3306
RedisCluster:
  - Host: ${LOCAL_ENDPOINT}:6379
DatadogProfiler:
  Enabled: true
  Host: ${LOCAL_ENDPOINT}:8126
Consul:
  Host: ${LOCAL_ENDPOINT}:8500 # consul endpoint
  Key: {{.serviceName}}.rpc # service name registered to Consul
  Meta:
    Protocol: grpc
  Tag:
    - {{.serviceName}}
    - rpc