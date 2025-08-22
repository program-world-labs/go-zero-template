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
  Endpoint: http://${LOCAL_HOST}:14268/api/traces
  Sampler: 1.0
  Batcher: jaeger
Etcd:
  Hosts:
  - ${LOCAL_HOST}:2379
  Key: userservice.rpc
Mode: dev

Env: ${APP_ENV}
Version: ${APP_VERSION}
DataSource:
  Host: root:root_password@tcp(${LOCAL_HOST}:3306)/user?charset=utf8mb4&parseTime=True&loc=UTC
RedisCluster:
  - Host: ${LOCAL_HOST}:6379
DatadogProfiler:
  Enabled: false
  Host: ${LOCAL_HOST}:8126
Event:
  Component: kafka
 # PubSub:
 #   Host: ${LOCAL_HOST}
 #   Port: 8085
 #   ProjectID: test
 #   SchemaRegistry:
 #     URL: 'http://${LOCAL_HOST}:8081'
 #     Versioned:
 #       - Topic: 'BaseEvent'
 #         Compatibility: 'FORWARD'
 #         Versions:
 #           - SchemaPath: '../../../libs/protoc/event/common_event/base_event.proto'
 #             Description: '基礎事件 Schema v1'
 #       - Topic: 'UserTopicEvent'
 #         Compatibility: 'FORWARD'
 #         Versions:
 #           - SchemaPath: '../../../libs/protoc/event/user_event/user_event.proto'
 #             Description: '使用者事件 Schema v1'
 #             References:
 #               - Name: 'event/common_event/base_event.proto'
 #                 Subject: 'BaseEvent-value'
 #                 Version: 0
 #   Consumer:
 #     Enabled: true
 #     SubscriptionSuffix: ''
 #     MaxOutstandingMessages: 1000
 #     MaxOutstandingBytes: 1073741824
 #     AckDeadlineSeconds: 60
 #   Producer:
 #     Enabled: true
 #     FlushIntervalMs: 100
 #     BatchEnabled: true
 #     BatchBytes: 1048576
 #     BatchTimeoutMs: 1000
  Kafka:
    Brokers:
      - ${LOCAL_HOST}:29092
    SchemaRegistry:
      URL: 'http://${LOCAL_HOST}:8081'
      Versioned:
        - Topic: 'BaseEvent'
          Compatibility: 'FORWARD'
          Versions:
            - SchemaPath: '../../../libs/protoc/event/common_event/base_event.proto'
              Description: '基礎事件 Schema v1'
#        - Topic: 'UserTopicEvent'
#          Compatibility: 'FORWARD'
#          Versions:
#            - SchemaPath: '../../../libs/protoc/event/user_event/user_event.proto'
#              Description: '使用者事件 Schema v1'
#              References:
#                - Name: 'event/common_event/base_event.proto'
#                  Subject: 'BaseEvent-value'
#                  Version: 0
    Consumer:
      Enabled: false
      GroupID: userservice
      MaxOutstandingMessages: 1000
      MaxOutstandingBytes: 1073741824
      AckDeadlineSeconds: 60
    Producer:
      Enabled: true
      FlushIntervalMs: 100
      BatchEnabled: true
      BatchBytes: 1048576
      BatchTimeoutMs: 1000

  Topics:
    Producer:
#      UserTopic: 'UserTopicEvent'
    Consumer:
#      UserTopic: 'UserTopicEvent'
MigratePath: '../../../resources/db/{{.serviceName}}'
SeedPath: '../../../resources/seed/{{.serviceName}}'