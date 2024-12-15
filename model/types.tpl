type (
	{{.lowerStartCamelObject}}Model interface{
		{{.method}}
	}

	CacheKeyGenerator func(data *{{.upperStartCamelObject}}) []string

	default{{.upperStartCamelObject}}Model struct {
		{{if .withCache}}sqlc.CachedConn{{else}}conn sqlx.SqlConn{{end}}
		table 		string
		redisCache 	*redis.Redis
		conn       	sqlx.SqlConn
		isCluster  	bool
		keyGenerators []CacheKeyGenerator
		patternGenerators []CacheKeyGenerator
	}

	{{.upperStartCamelObject}} struct {
		{{.fields}}
	}

	{{.upperStartCamelObject}}Page struct {
		Limit int64
		Page  int64
	}

	{{.upperStartCamelObject}}Filter struct {
		Field    string
		Operator string
		Value    interface{}
	}

	{{.upperStartCamelObject}}Order struct {
		Field string
		Dir   string
	}

)
