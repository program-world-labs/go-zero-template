func (m *default{{.upperStartCamelObject}}Model) GetConn() sqlx.SqlConn {
	return m.conn
}


func (m *default{{.upperStartCamelObject}}Model) deleteRedisPatternCache(ctx context.Context, data *{{.upperStartCamelObject}}) error {
	if m.redisCache == nil {
		return nil
	}

	if len(m.patternGenerators) == 0 {
		return nil
	}

	var cursor uint64
	for _, generator := range m.patternGenerators {
		patterns := generator(data)
		for _, pattern := range patterns {
			for {
				// 使用 SCAN 获取匹配的键
				keys, nextCursor, err := m.redisCache.ScanCtx(ctx, cursor, pattern, 0)
				if err != nil {
					return err
				}

				// 如果有键需要删除，使用 PipelinedCtx 批量删除
				if len(keys) > 0 {
					err = m.redisCache.PipelinedCtx(ctx, func(pipe redis.Pipeliner) error {
						if m.isCluster {
							for _, key := range keys {
								pipe.Del(ctx, key)
							}
						} else {
							pipe.Del(ctx, keys...)
						}
						return nil
					})
					if err != nil {
						return err
					}
				}

				cursor = nextCursor
				if cursor == 0 {
					break
				}
			}
		}
	}
	return nil
}

func (m *default{{.upperStartCamelObject}}Model) structToMap(data *{{.upperStartCamelObject}}) (map[string]interface{}, error) {
	{{.lowerStartCamelObject}}Type := reflect.TypeOf(*data)
	{{.lowerStartCamelObject}}Value := reflect.ValueOf(*data)

	{{.lowerStartCamelObject}}Map := make(map[string]interface{})

	for i := 0; i < {{.lowerStartCamelObject}}Type.NumField(); i++ {
		field := {{.lowerStartCamelObject}}Type.Field(i)
		fieldName := field.Name
		fieldValue := {{.lowerStartCamelObject}}Value.Field(i)

		if fieldValue.CanInterface() {
			{{.lowerStartCamelObject}}Map[fieldName] = fieldValue.Interface()
		}
	}

	return {{.lowerStartCamelObject}}Map, nil
}

func (m *default{{.upperStartCamelObject}}Model) addFilter(query string, filters []*{{.upperStartCamelObject}}Filter, softDelete bool) (string, []interface{}) {
	args := make([]interface{}, 0)
	if len(filters) == 0 {
		return query, args
	}
	if !softDelete {
		query += " WHERE "
	} else {
		query += " AND "
	}
	for idx, filter := range filters {
		if idx > 0 {
			query += " AND "
		}
		query += fmt.Sprintf("`%s` %s ?", filter.Field, filter.Operator)
		args = append(args, filter.Value)
	}
	return query, args
}

func (m *default{{.upperStartCamelObject}}Model) addOrder(query string, orders []*{{.upperStartCamelObject}}Order) (string, []interface{}) {
	args := make([]interface{}, 0)
	if len(orders) == 0 {
		return query + " ORDER BY {{.originalPrimaryKey}} DESC", args // 默认排序
	}
	query += " ORDER BY "
	for i, order := range orders {
		if i > 0 {
			query += ", "
		}
		query += fmt.Sprintf("`%s` %s", order.Field, order.Dir)
	}
	return query, args
}

func (m *default{{.upperStartCamelObject}}Model) getFindsAllQueryString(page *{{.upperStartCamelObject}}Page, filters []*{{.upperStartCamelObject}}Filter, orders []*{{.upperStartCamelObject}}Order, softDelete bool) (string, []interface{}) {
	if page == nil {
		page = &{{.upperStartCamelObject}}Page{
			Limit: 0,
			Page:  0,
		}
	}
	offset := (page.Page - 1) * page.Limit
	if offset < 0 {
		offset = 0
	}
	listQuery := "SELECT %s FROM %s"
	if softDelete {
		listQuery += " WHERE `deleted_at` IS NULL"
	}
	listQuery, args := m.addFilter(listQuery, filters, softDelete)
	listQuery, orderArgs := m.addOrder(listQuery, orders)
	args = append(args, orderArgs...)
	
	if page.Limit > 0 {
		listQuery += " LIMIT ? OFFSET ?"
		args = append(args, page.Limit, offset)
	}
	return listQuery, args
}

func (m *default{{.upperStartCamelObject}}Model) getFindsAllCountQueryString(filters []*{{.upperStartCamelObject}}Filter, softDelete bool) (string, []interface{}) {
	countQuery := "SELECT COUNT(*) FROM %s "
	if softDelete {
		countQuery += "WHERE `deleted_at` IS NULL "
	}
	countQuery, args := m.addFilter(countQuery, filters, softDelete)
	return countQuery, args
}


func migrateDB(path string, db *sql.DB) error {
	driver, err := mysql.WithInstance(db, &{{if .postgreSql}}postgres{{else}}mysql{{end}}.Config{})
	if err != nil {
		log.Fatalf("Failed to get raw database connection: %v", err)
	}
	m, err := migrate.NewWithDatabaseInstance(
		"file://"+path,
		"{{if .postgreSql}}postgres{{else}}mysql{{end}}",
		driver,
	)
	if err != nil {
		log.Fatalf("Failed to create migrate instance: %v", err)
	}
	// m.Down()
	err = m.Up()
	if err != nil && err != migrate.ErrNoChange {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	return nil
}
