package svc

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/cockroachdb/errors"
	{{.imports}}
	"needle/libs/pwpkg/event"
	kafkaevent "needle/libs/pwpkg/event/kafka"
	pubsubevent "needle/libs/pwpkg/event/pubsub"
	"needle/libs/pwpkg/pwlogger"
	"needle/libs/pwpkg/store/transaction"

	"cloud.google.com/go/pubsub"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
	"google.golang.org/protobuf/proto"
)

type ServiceContext struct {
	Config config.Config

	// 基礎設施層
	Event              event.IEvent
	TransactionManager *transaction.SqlxTransactionManager
	Logger             *pwlogger.LogxAdapter
}

func NewServiceContext(c config.Config) (*ServiceContext, error) {
	// ----- 配置驗證與設置預設值 (最優先) -----
	config.SetDefaults(&c)

	// ----- 日誌系統初始化 -----
	logger := initLogger(c)

	// ----- 資料庫及事務管理器初始化 -----
	dbConn, err := initDatabase(c)
	if err != nil {
		return nil, errors.Newf("failed to initialize database: %w", err)
	}

	txManager := transaction.NewSqlxTransactionManager(dbConn)

	// ----- 事件系統初始化 -----
	eventImpl, err := initEventSystem(c, logger)
	if err != nil {
		return nil, errors.Newf("failed to initialize event system: %w", err)
	}

	// ----- 基礎設施層初始化 -----
	_, err = initInfrastructure(c, dbConn, eventImpl, logger)
	if err != nil {
		return nil, errors.Newf("failed to initialize infrastructure: %w", err)
	}

	// ----- 倉儲層初始化 -----

	// ----- 應用服務初始化 -----

	return &ServiceContext{
		Config:             c,
		Event:              eventImpl,
		TransactionManager: txManager,
		Logger:             logger,
	}, nil
}

type InfrastructureComponents struct {
}

// initLogger 初始化日誌系統
func initLogger(c config.Config) *pwlogger.LogxAdapter {
	adapter := pwlogger.NewLogxAdapter(
		context.Background(),
		c.Name,
		c.Env,
		c.Version,
	)
	// 類型斷言獲取具體類型
	if logxAdapter, ok := adapter.(*pwlogger.LogxAdapter); ok {
		return logxAdapter
	}
	// 如果斷言失敗，創建一個新的 LogxAdapter
	return &pwlogger.LogxAdapter{}
}

// initDatabase 初始化資料庫連接
func initDatabase(c config.Config) (sqlx.SqlConn, error) {
	conn := sqlx.NewMysql(c.DataSource.Host)

	// 設置連接池參數
	rawDB, err := conn.RawDB()
	if err != nil {
		return nil, fmt.Errorf("failed to get raw database connection: %w", err)
	}

	// 測試資料庫連接
	if err := rawDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return conn, nil
}

// initEventSystem 初始化事件系統
func initEventSystem(c config.Config, logger *pwlogger.LogxAdapter) (event.IEvent, error) {
	switch c.Event.Component {
	case "kafka":
		return initKafka(c, logger)
	case "pubsub":
		return initPubsub(c, logger)
	default:
		return initKafka(c, logger) // 預設使用 Kafka
	}
}

// initInfrastructure 初始化基礎設施組件
func initInfrastructure(c config.Config, dbConn sqlx.SqlConn, eventImpl event.IEvent, logger *pwlogger.LogxAdapter) (*InfrastructureComponents, error) {
	// 初始化用戶模型
	// cacheConf := cache.WithExpiry(time.Minute * 1)
	// userModel := usersmodel.NewUsersModel(
	// 	dbConn,
	// 	c.MigratePath,
	// 	c.RedisCluster,
	// 	cacheConf,
	// )

	// 獲取原始資料庫連接
	// rawDB, err := dbConn.RawDB()
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to get raw database connection: %w", err)
	// }

	// 初始化用戶事件數據源
	// userTopicEvent, err := user_topic_event.NewUserTopicEvent(
	// 	rawDB,
	// 	eventImpl.GetPublisher(),
	// 	logger,
	// 	c.Event.Topics.Producer.UserTopic,
	// )
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to initialize user topic event: %w", err)
	// }

	return &InfrastructureComponents{}, nil
}

// initPubsub 初始化 PubSub 客戶端
func initPubsub(c config.Config, logger *pwlogger.LogxAdapter) (*pubsubevent.PubSubEventImpl, error) {
	// 創建 PubSub 選項
	var opts []pubsubevent.Option

	// 設置 Watermill 日誌記錄器
	opts = append(opts, pubsubevent.WithWatermillLogger(logger))

	// 設置 Schema Registry 配置
	schemaConfig, err := initPubSubSchemaRegistry(c)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize PubSub schema registry: %w", err)
	}
	opts = append(opts, pubsubevent.WithSchemaRegistry(*schemaConfig))

	// 本地模擬器配置
	if c.Event.PubSub.Host != "" {
		opts = append(opts, pubsubevent.WithLocalEmulator(pubsubevent.LocalEmulatorConfig{
			Enabled: true,
			Host:    c.Event.PubSub.Host,
			Port:    c.Event.PubSub.Port,
		}))
	}

	// 設置消費者配置
	if c.Event.PubSub.Consumer.Enabled {
		consumerConfig := pubsubevent.ConsumerConfig{
			SubscriptionSuffix:     c.Event.PubSub.Consumer.SubscriptionSuffix,
			MaxOutstandingMessages: c.Event.PubSub.Consumer.MaxOutstandingMessages,
			MaxOutstandingBytes:    c.Event.PubSub.Consumer.MaxOutstandingBytes,
			AckDeadline:            time.Duration(c.Event.PubSub.Consumer.AckDeadlineSeconds) * time.Second,
		}
		opts = append(opts, pubsubevent.WithConsumerConfig(consumerConfig))
	}

	// 設置生產者配置
	if c.Event.PubSub.Producer.Enabled {
		producerConfig := pubsubevent.ProducerConfig{
			FlushPeriod:          time.Duration(c.Event.PubSub.Producer.FlushIntervalMs) * time.Millisecond,
			ExecutorBatchEnabled: c.Event.PubSub.Producer.BatchEnabled,
			ExecutorBatchBytes:   c.Event.PubSub.Producer.BatchBytes,
			ExecutorBatchTimeout: time.Duration(c.Event.PubSub.Producer.BatchTimeoutMs) * time.Millisecond,
		}
		opts = append(opts, pubsubevent.WithProducerConfig(producerConfig))
	}

	// 創建 PubSub 客戶端
	pubsubClient := pubsubevent.NewPubSubEventImpl(c.Event.PubSub.ProjectID, opts...)

	// 初始化生產者和消費者
	if c.Event.PubSub.Producer.Enabled {
		if err := pubsubClient.InitProducer(); err != nil {
			return nil, fmt.Errorf("failed to initialize pubsub producer: %w", err)
		}
	}

	if c.Event.PubSub.Consumer.Enabled {
		if err := pubsubClient.InitConsumer(); err != nil {
			return nil, fmt.Errorf("failed to initialize pubsub consumer: %w", err)
		}
	}

	return pubsubClient, nil
}

// initPubSubSchemaRegistry 初始化 PubSub Schema Registry 配置
func initPubSubSchemaRegistry(c config.Config) (*pubsubevent.SchemaRegistryConfig, error) {
	schemaConfig := pubsubevent.NewDefaultSchemaRegistryConfig()
	schemaConfig.ProjectID = c.Event.PubSub.ProjectID

	// 註冊消息類型
	schemaConfig.RegisterMessageType("type.googleapis.com/event.user_event.UserEvent", func() proto.Message {
		// return &userevent.UserEvent{}
		return nil
	})
	schemaConfig.RegisterMessageType("type.googleapis.com/event.common_event.BaseEvent", func() proto.Message {
		// return &commonevent.BaseEvent{}
		return nil
	})

	// 處理版本化 schema 配置
	if len(c.Event.PubSub.SchemaRegistry.Versioned) > 0 {
		for _, vConfig := range c.Event.PubSub.SchemaRegistry.Versioned {
			for _, version := range vConfig.Versions {
				// 讀取 proto 文件內容
				protoContent, err := readSchemaFile(version.SchemaPath)
				if err != nil {
					return nil, fmt.Errorf("failed to read schema file %s: %w", version.SchemaPath, err)
				}

				schemaName := fmt.Sprintf("projects/%s/schemas/%s", c.Event.PubSub.ProjectID, vConfig.Topic)
				// 註冊 schema 定義
				schemaConfig.RegisterSchema(vConfig.Topic, pubsubevent.SchemaDefinition{
					Name:       schemaName,
					Type:       pubsub.SchemaProtocolBuffer,
					Definition: string(protoContent),
				})
			}
		}
	}

	return &schemaConfig, nil
}

// initKafka 初始化 Kafka 事件發布者與消費者
func initKafka(c config.Config, logger *pwlogger.LogxAdapter) (*kafkaevent.WaterMillEventImpl, error) {
	// 統一使用版本化 Schema Registry
	schemaRegistry, err := initVersionedSchemaRegistry(c)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Versioned Schema Registry: %w", err)
	}

	eventImpl := kafkaevent.NewWaterMillEventImpl(
		c.Event.Kafka.Brokers,
		kafkaevent.WithSchemaRegistry(schemaRegistry.GetConfig()),
		kafkaevent.WithEnableExecutors(c.Event.Kafka.Producer.BatchEnabled),
		kafkaevent.WithExecutorBatchTimeout(time.Duration(c.Event.Kafka.Producer.BatchTimeoutMs)*time.Millisecond),
		kafkaevent.WithGroupID(c.Event.Kafka.Consumer.GroupID),
	)

	if c.Event.Kafka.Producer.Enabled {
		if err := eventImpl.InitProducer(); err != nil {
			return nil, fmt.Errorf("failed to initialize Kafka producer: %w", err)
		}
	}

	if c.Event.Kafka.Consumer.Enabled {
		if err := eventImpl.InitConsumer(); err != nil {
			return nil, fmt.Errorf("failed to initialize Kafka consumer: %w", err)
		}
	}

	return eventImpl, nil
}

// initVersionedSchemaRegistry 初始化版本化 Schema Registry
func initVersionedSchemaRegistry(c config.Config) (*kafkaevent.VersionedSchemaRegistry, error) {
	// 檢查 Schema Registry URL 是否配置
	if c.Event.Kafka.SchemaRegistry.URL == "" {
		return nil, fmt.Errorf("kafka schema registry URL is required")
	}

	// 轉換配置格式
	var versionedConfigs []kafkaevent.VersionedSchemaConfigDef

	for _, vConfig := range c.Event.Kafka.SchemaRegistry.Versioned {
		// 轉換版本定義
		var versions []kafkaevent.SchemaVersionDefFile
		for _, version := range vConfig.Versions {
			// 轉換引用
			var references []kafkaevent.SchemaReferenceFile
			for _, ref := range version.References {
				references = append(references, kafkaevent.SchemaReferenceFile{
					Name:    ref.Name,
					Subject: ref.Subject,
					Version: ref.Version,
				})
			}

			versions = append(versions, kafkaevent.SchemaVersionDefFile{
				SchemaPath:  version.SchemaPath,
				Description: version.Description,
				References:  references,
			})
		}

		versionedConfigs = append(versionedConfigs, kafkaevent.VersionedSchemaConfigDef{
			Topic:         vConfig.Topic,
			Compatibility: vConfig.Compatibility,
			Versions:      versions,
		})
	}

	// 創建版本化 Schema Registry
	return kafkaevent.NewVersionedSchemaRegistryFromConfig(c.Event.Kafka.SchemaRegistry.URL, versionedConfigs)
}

// readSchemaFile 讀取 schema 文件內容
func readSchemaFile(filePath string) ([]byte, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filePath, err)
	}
	return content, nil
}

