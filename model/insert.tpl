func (m *default{{.upperStartCamelObject}}Model) Insert(ctx context.Context, data *{{.upperStartCamelObject}}) (sql.Result,error) {
	{{if .withCache}}
	{{.keys}}
	keys := []string{
		{{.keyValues}},
	}
	for _, generator := range m.keyGenerators {
		keys = append(keys, generator(data)...)
	}
	ret, err := m.ExecCtx(ctx, func(ctx context.Context, conn sqlx.SqlConn) (result sql.Result, err error) {
		{{if .withCache}}
		// 更新 Redis 缓存
		err = m.deleteRedisListCache(ctx, cache{{.upperStartCamelObject}}ListPrefix+"*")
		if err != nil {
			return nil, err
		}
		{{end}}
		query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
		return conn.ExecCtx(ctx, query, {{.expressionValues}})
	}, keys...)
	{{else}}
	query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
	ret,err:=m.conn.ExecCtx(ctx, query, {{.expressionValues}})
	{{end}}
	return ret,err
}
