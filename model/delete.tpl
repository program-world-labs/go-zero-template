func (m *default{{.upperStartCamelObject}}Model) Delete(ctx context.Context, data *{{.upperStartCamelObject}}, softDelete bool) error {
	{{if .withCache}}{{if .containsIndexCache}}data, err:=m.FindOne(ctx, data.Id, softDelete)
	if err!=nil{
		return err
	}

{{end}}	{{.keys}}
	keys := []string{
		{{.keyValues}},
	}
	for _, generator := range m.keyGenerators {
		keys = append(keys, generator(data)...)
	}
    _, err {{if .containsIndexCache}}={{else}}:={{end}} m.ExecCtx(ctx, func(ctx context.Context, conn sqlx.SqlConn) (result sql.Result, err error) {
		{{if .withCache}}// 更新 Redis 缓存
		err = m.deleteRedisPatternCache(ctx, data)
		if err != nil {
			return nil, err
		}{{end}}
		var query string
		args := []interface{}{}
		if softDelete {
			query = fmt.Sprintf("update %s set `deleted_at` = FROM_UNIXTIME({{if .postgreSql}}$1{{else}}?{{end}}) where {{.originalPrimaryKey}} = {{if .postgreSql}}$2{{else}}?{{end}}", m.table)
			args = append(args, time.Now().Unix())
		} else {
			query = fmt.Sprintf("delete from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table)
		}
		args = append(args, data.Id)
		return conn.ExecCtx(ctx, query, args...)
	}, keys...){{else}}query := fmt.Sprintf("delete from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table)
		_,err:=m.conn.ExecCtx(ctx, query, {{.lowerStartCamelPrimaryKey}}){{end}}
	return err
}
