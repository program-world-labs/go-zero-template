func (m *default{{.upperStartCamelObject}}Model) FindOne(ctx context.Context, {{.lowerStartCamelPrimaryKey}} {{.dataType}}, softDelete bool) (*{{.upperStartCamelObject}}, error) {
	{{if .withCache}}{{.cacheKey}}
	var resp {{.upperStartCamelObject}}
	err := m.QueryRowCtx(ctx, &resp, {{.cacheKeyVariable}}, func(ctx context.Context, conn sqlx.SqlConn, v any) error {
		var query string
		if softDelete {
			query =  fmt.Sprintf("select %s from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null limit 1", {{.lowerStartCamelObject}}Rows, m.table)
		} else {
			query =  fmt.Sprintf("select %s from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} limit 1", {{.lowerStartCamelObject}}Rows, m.table)
		}
		return conn.QueryRowCtx(ctx, v, query, {{.lowerStartCamelPrimaryKey}})
	})
	switch err {
	case nil:
		return &resp, nil
	case sqlc.ErrNotFound:
		return nil, ErrNotFound
	default:
		return nil, err
	}{{else}}var query string
	if softDelete {
		query = fmt.Sprintf("select %s from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} and `deleted_at` is null limit 1", {{.lowerStartCamelObject}}Rows, m.table)
	} else {
		query = fmt.Sprintf("select %s from %s where {{.originalPrimaryKey}} = {{if .postgreSql}}$1{{else}}?{{end}} limit 1", {{.lowerStartCamelObject}}Rows, m.table)
	}
	var resp {{.upperStartCamelObject}}
	err := m.conn.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelPrimaryKey}})
	switch err {
	case nil:
		return &resp, nil
	case sqlx.ErrNotFound:
		return nil, ErrNotFound
	default:
		return nil, err
	}{{end}}
}

func (m *default{{.upperStartCamelObject}}Model) FindList(ctx context.Context, page *{{.upperStartCamelObject}}Page, filters []*{{.upperStartCamelObject}}Filter, orders []*{{.upperStartCamelObject}}Order, softDelete bool) ([]*{{.upperStartCamelObject}}, int32, error) {
	{{if .withCache}}{{.lowerStartCamelObject}}IdKey := fmt.Sprintf("%s%v%v%v", cache{{.upperStartCamelObject}}ListPrefix, page, filters, orders)
	{{.lowerStartCamelObject}}CountKey := fmt.Sprintf("%s%v%v%v", cache{{.upperStartCamelObject}}CountPrefix, page, filters, orders)
	var resp []*{{.upperStartCamelObject}}
	var totalCount int32
	err := m.QueryRowCtx(ctx, &resp, {{.lowerStartCamelObject}}IdKey, func(ctx context.Context, conn sqlx.SqlConn, v any) error {
		queryStr, args := m.getFindsAllQueryString(page, filters, orders, softDelete)
		finalQuery := fmt.Sprintf(queryStr, {{.lowerStartCamelObject}}Rows, m.table)
		return conn.QueryRowsCtx(ctx, v, finalQuery, args...)
	})
	if err != nil {
		return nil, 0, err
	}

	err = m.QueryRowCtx(ctx, &totalCount, {{.lowerStartCamelObject}}CountKey, func(ctx context.Context, conn sqlx.SqlConn, v any) error {
		queryStr, args := m.getFindsAllCountQueryString(filters, softDelete)
		countQuery := fmt.Sprintf(queryStr, m.table)
		return conn.QueryRowCtx(ctx, v, countQuery, args...)
	})
	switch err {
	case nil:
		return resp, totalCount, nil
	case sqlc.ErrNotFound:
		return nil, 0, ErrNotFound
	default:
		return nil, 0, err
	}{{else}}queryStr, args := m.getFindsAllQueryString(page, filters, orders, softDelete)
	countQueryStr, args := m.getFindsAllCountQueryString(filters, softDelete)
	var resp {{.upperStartCamelObject}}
	var totalCount int32
	err := m.conn.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelPrimaryKey}})
	if err != nil {
		return nil, 0, err
	}

	err = m.conn.QueryRowCtx(ctx, &totalCount, countQueryStr, {{.lowerStartCamelPrimaryKey}})
	switch err {
	case nil:
		return &resp, totalCount, nil
	case sqlx.ErrNotFound:
		return nil, 0, ErrNotFound
	default:
		return nil, 0, err
	}{{end}}

}