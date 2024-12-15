func (m *default{{.upperStartCamelObject}}Model) Update(ctx context.Context, {{if .containsIndexCache}}newData{{else}}data{{end}} *{{.upperStartCamelObject}}, softDelete bool) error {
	{{if .withCache}}{{if .containsIndexCache}}data, err:=m.FindOne(ctx, newData.{{.upperStartCamelPrimaryKey}}, softDelete)
	if err!=nil{
		return err
	}

{{end}}	{{.keys}}
	keys := []string{
		{{.keyValues}},
	}
	for _, generator := range m.keyGenerators {
		keys = append(keys, generator({{if .containsIndexCache}}newData{{else}}data{{end}})...)
	}
    _, {{if .containsIndexCache}}err{{else}}err:{{end}}= m.ExecCtx(ctx, func(ctx context.Context, conn sqlx.SqlConn) (result sql.Result, err error) {
		// 更新 Redis 缓存
		err = m.deleteRedisPatternCache(ctx, {{if .containsIndexCache}}newData{{else}}data{{end}})
		if err != nil {
			return nil, err
		}
		
		var query string
		if softDelete {
			query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null", m.table, {{.lowerStartCamelObject}}RowsWithPlaceHolder)
		} else {
			query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table, {{.lowerStartCamelObject}}RowsWithPlaceHolder)
		}
		return conn.ExecCtx(ctx, query, {{.expressionValues}})
	}, keys...){{else}}var query string
	if softDelete {
		query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null", m.table, {{.lowerStartCamelObject}}RowsWithPlaceHolder)
	} else {
		query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table, {{.lowerStartCamelObject}}RowsWithPlaceHolder)
	}
    _,err:=m.conn.ExecCtx(ctx, query, {{.expressionValues}}){{end}}
	return err
}

func (m *default{{.upperStartCamelObject}}Model) UpdateWithFields(ctx context.Context, {{if .containsIndexCache}}newData{{else}}data{{end}} *{{.upperStartCamelObject}}, fields []string, softDelete bool) error {
	{{if .withCache}}{{if .containsIndexCache}}data, err:=m.FindOne(ctx, newData.{{.upperStartCamelPrimaryKey}}, softDelete)
	if err!=nil{
		return err
	}

{{end}}	{{.keys}}
	keys := []string{
		{{.keyValues}},
	}
	for _, generator := range m.keyGenerators {
		keys = append(keys, generator({{if .containsIndexCache}}newData{{else}}data{{end}})...)
	}
	{{.lowerStartCamelObject}}Map, err := m.structToMap({{if .containsIndexCache}}newData{{else}}data{{end}})
	if err!=nil {
		return err
	}
	setClause := make([]string, 0, len(fields))
	args := make([]interface{}, 0, len(fields)+1)

	rows := strings.Replace({{.lowerStartCamelObject}}Rows, "`", "", -1)
	allowFields := strings.Split(rows, ",")
	for _, field := range fields {
		if !slices.Contains(allowFields, field) {
			return fmt.Errorf("非法的字段名稱: %s", field)
		}
		setClause = append(setClause, fmt.Sprintf("`%s` = ?", field))
		args = append(args, {{.lowerStartCamelObject}}Map[strcase.ToPascal(field)])
	}

	if len(setClause) == 0 {
		return fmt.Errorf("没有指定要更新的字段")
	}

	_, err = m.ExecCtx(ctx, func(ctx context.Context, conn sqlx.SqlConn) (result sql.Result, err error) {
		// 更新 Redis 缓存
		err = m.deleteRedisPatternCache(ctx, {{if .containsIndexCache}}newData{{else}}data{{end}})
		if err != nil {
			return nil, err
		}
		var query string
		if softDelete {
			query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null", m.table, strings.Join(setClause, ", "))
		} else {
			query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table, strings.Join(setClause, ", "))
		}
		args = append(args, data.{{.upperStartCamelPrimaryKey}})
		return conn.ExecCtx(ctx, query, args...)
	}, keys...){{else}}var query string
	if softDelete {
		query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null", m.table, strings.Join(setClause, ", "))
	} else {
		query = fmt.Sprintf("update %s set %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}}", m.table, strings.Join(setClause, ", "))
	}
    _,err:=m.conn.ExecCtx(ctx, query, {{.expressionValues}}){{end}}
	return err
}
