package config

import (
	"github.com/cockroachdb/errors"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/zrpc"
)

type Config struct {
	zrpc.RpcServerConf
	Env        string
	Version    string
	DataSource struct {
		Host string
	}
	RedisCluster    cache.CacheConf
	DatadogProfiler struct {
		Enabled bool
		Host    string
	}
	Event EventConfig

	// 路徑配置
	MigratePath string
	SeedPath    string
}

// Validate 實現 go-zero 原生的 Validator 接口
// 配置載入後會自動調用此方法進行驗證
func (c Config) Validate() error {
	// 基本配置驗證
	if c.Name == "" {
		return errors.New("service name is required")
	}

	if c.DataSource.Host == "" {
		return errors.New("database host is required")
	}

	// 事件系統配置驗證
	if err := c.Event.Validate(); err != nil {
		return errors.Newf("event config validation failed: %w", err)
	}

	return nil
}

type EventConfig struct {
	Component string       `json:"component,default=kafka,options=kafka|pubsub"`
	PubSub    PubSubConfig `json:"pubsub,optional"`
	Kafka     KafkaConfig  `json:"kafka,optional"`
	Topics    EventTopics
}

// Validate 驗證事件配置
func (e EventConfig) Validate() error {
	switch e.Component {
	case "kafka":
		return e.Kafka.Validate()
	case "pubsub":
		return e.PubSub.Validate()
	case "":
		// 如果未設置，使用預設值 kafka，不報錯
		return KafkaConfig{}.Validate()
	default:
		return errors.Newf("unsupported event component: %s", e.Component)
	}
}

type EventTopics struct {
	Producer EventProducer
	Consumer EventConsumer
}

type EventConsumer struct {
	// UserTopic string
}

type EventProducer struct {
	// UserTopic string
}

type KafkaConfig struct {
	Brokers        []string
	SchemaRegistry SchemaRegistryConfig
	Consumer       KafkaConsumer `json:"consumer,optional"`
	Producer       KafkaProducer `json:"producer,optional"`
}

// Validate 驗證 Kafka 配置
func (k KafkaConfig) Validate() error {
	if len(k.Brokers) == 0 {
		return errors.Newf("kafka brokers are required")
	}

	if k.Consumer.Enabled && k.Consumer.GroupID == "" {
		return errors.Newf("kafka consumer group ID is required when consumer is enabled")
	}

	return k.SchemaRegistry.Validate()
}

type KafkaProducer struct {
	Enabled         bool
	FlushIntervalMs int
	BatchEnabled    bool
	BatchBytes      int
	BatchTimeoutMs  int
}

type KafkaConsumer struct {
	Enabled                bool
	GroupID                string
	MaxOutstandingMessages int
	MaxOutstandingBytes    int
	AckDeadlineSeconds     int
}

type PubSubConfig struct {
	ProjectID      string
	Host           string
	Port           int
	SchemaRegistry SchemaRegistryConfig
	Consumer       PubSubConsumer
	Producer       PubSubProducer
}

// Validate 驗證 PubSub 配置
func (p PubSubConfig) Validate() error {
	if p.ProjectID == "" {
		return errors.Newf("pubsub project ID is required")
	}

	return p.SchemaRegistry.Validate()
}

type PubSubProducer struct {
	Enabled         bool
	FlushIntervalMs int
	BatchEnabled    bool
	BatchBytes      int
	BatchTimeoutMs  int
}

type PubSubConsumer struct {
	Enabled                bool
	SubscriptionSuffix     string
	MaxOutstandingMessages int
	MaxOutstandingBytes    int
	AckDeadlineSeconds     int
}

type SchemaRegistryConfig struct {
	URL       string
	Versioned []VersionedSchemaConfig
}

// Validate 驗證 Schema Registry 配置
func (s SchemaRegistryConfig) Validate() error {
	if s.URL == "" && len(s.Versioned) > 0 {
		return errors.Newf("schema registry URL is required when versioned schemas are configured")
	}

	for _, vConfig := range s.Versioned {
		if err := vConfig.Validate(); err != nil {
			return err
		}
	}

	return nil
}

type VersionedSchemaConfig struct {
	Topic         string
	Compatibility string
	Versions      []SchemaVersionDef
}

// Validate 驗證版本化 Schema 配置
func (v VersionedSchemaConfig) Validate() error {
	if v.Topic == "" {
		return errors.Newf("schema topic cannot be empty")
	}

	if len(v.Versions) == 0 {
		return errors.Newf("schema must have at least one version for topic: %s", v.Topic)
	}

	for i, version := range v.Versions {
		if err := version.Validate(); err != nil {
			return errors.Newf("invalid version %d for topic %s: %w", i+1, v.Topic, err)
		}
	}

	return nil
}

type SchemaVersionDef struct {
	SchemaPath  string
	Description string
	References  []SchemaReference `json:"references,optional"`
}

// Validate 驗證 Schema 版本定義
func (s SchemaVersionDef) Validate() error {
	if s.SchemaPath == "" {
		return errors.Newf("schema path cannot be empty")
	}

	for i, ref := range s.References {
		if err := ref.Validate(); err != nil {
			return errors.Newf("invalid reference %d: %w", i+1, err)
		}
	}

	return nil
}

type SchemaReference struct {
	Name    string
	Subject string
	Version int
}

// Validate 驗證 Schema 引用
func (s SchemaReference) Validate() error {
	if s.Name == "" {
		return errors.Newf("schema reference name cannot be empty")
	}

	if s.Subject == "" {
		return errors.Newf("schema reference subject cannot be empty")
	}

	if s.Version < 0 {
		return errors.Newf("schema reference version cannot be negative")
	}

	return nil
}


// SetDefaults 設置配置預設值
func SetDefaults(c *Config) {
	// 事件系統預設值
	setEventDefaults(&c.Event)
}

// setEventDefaults 設置事件系統預設值
func setEventDefaults(eventConfig *EventConfig) {
	if eventConfig.Component == "" {
		eventConfig.Component = "kafka"
	}

	// Kafka 預設值
	if !eventConfig.Kafka.Producer.Enabled {
		eventConfig.Kafka.Producer.Enabled = true
	}
	if eventConfig.Kafka.Producer.FlushIntervalMs == 0 {
		eventConfig.Kafka.Producer.FlushIntervalMs = 100
	}
	if eventConfig.Kafka.Producer.BatchTimeoutMs == 0 {
		eventConfig.Kafka.Producer.BatchTimeoutMs = 100
	}

	// PubSub 預設值
	if !eventConfig.PubSub.Producer.Enabled {
		eventConfig.PubSub.Producer.Enabled = true
	}
	if eventConfig.PubSub.Producer.FlushIntervalMs == 0 {
		eventConfig.PubSub.Producer.FlushIntervalMs = 100
	}
	if eventConfig.PubSub.Consumer.SubscriptionSuffix == "" {
		eventConfig.PubSub.Consumer.SubscriptionSuffix = "sub"
	}
}
