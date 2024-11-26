package config

import (
	"needle/libs/pwpkg/consul"

	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/zrpc"
)

type Config struct {
	zrpc.RpcServerConf
	Consul  consul.Conf
	Env     string
	Version string
	DataSource struct {
		Host string
	}
	RedisCluster cache.CacheConf
	DatadogProfiler struct {
		Enabled bool
		Host    string
	}
}
