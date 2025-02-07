func (m *default{{.upperStartCamelObject}}Model) Insert(ctx context.Context, data *{{.upperStartCamelObject}}, options ...OptionFunc) (sql.Result,error) {
	option := &Option{}
	for _, opt := range options {
		opt(option)
	}
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
		err = m.deleteRedisPatternCache(ctx, data)
		if err != nil {
			return nil, err
		}
		{{end}}
		query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
		if option.session != nil {
			return option.session.ExecCtx(ctx, query, {{.expressionValues}})
		}
		return conn.ExecCtx(ctx, query, {{.expressionValues}})
	}, keys...)
	{{else}}
	query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
	var err error
	if option.session != nil {
		ret, err = option.session.ExecCtx(ctx, query, {{.expressionValues}})
	} else {
		ret, err = m.conn.ExecCtx(ctx, query, {{.expressionValues}})
	}
	{{end}}
	return ret,err
}
