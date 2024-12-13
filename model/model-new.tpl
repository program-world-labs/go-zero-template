func new{{.upperStartCamelObject}}Model(conn sqlx.SqlConn{{if .withCache}}, migratePath string, c cache.CacheConf, opts ...cache.Option{{end}}) *default{{.upperStartCamelObject}}Model {
	redisCache, err := redis.NewRedis(c[0].RedisConf)
	if err != nil {
		panic(err)
	}

	db, err := conn.RawDB()
	if err != nil {
		panic(err)
	}

	err = migrateDB(migratePath, db)
	if err != nil {
		panic(err)
	}

	return &default{{.upperStartCamelObject}}Model{
		{{if .withCache}}CachedConn: sqlc.NewNodeConn(conn, redisCache, opts...){{else}}conn:conn{{end}},
		table:      {{.table}},
		redisCache: redisCache,
		conn:       conn,
		isCluster:  c[0].RedisConf.Type == "cluster",
	}
}

func (m *default{{.upperStartCamelObject}}Model) RegisterCacheKeyGenerator(generator CacheKeyGenerator) {
    m.keyGenerators = append(m.keyGenerators, generator)
}

// ClearCacheKeyGenerators 清空所有注册的生成器
func (m *default{{.upperStartCamelObject}}Model) ClearCacheKeyGenerators() {
    m.keyGenerators = []CacheKeyGenerator{}
}
