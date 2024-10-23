func new{{.upperStartCamelObject}}Model(conn sqlx.SqlConn{{if .withCache}}, c cache.CacheConf, opts ...cache.Option{{end}}) *default{{.upperStartCamelObject}}Model {
	redisCache, err := redis.NewRedis(c[0].RedisConf)
	if err != nil {
		panic(err)
	}

	return &default{{.upperStartCamelObject}}Model{
		{{if .withCache}}CachedConn: sqlc.NewNodeConn(conn, redisCache, opts...){{else}}conn:conn{{end}},
		table:      {{.table}},
		redisCache: redisCache,
	}
}

