func (m *default{{.upperStartCamelObject}}Model) FindOneBy{{.upperField}}(ctx context.Context, {{.in}}, options ...OptionFunc) (*{{.upperStartCamelObject}}, error) {
	option := &Option{}
	for _, opt := range options {
		opt(option)
	}

	{{if .withCache}}{{.cacheKey}}
	var resp {{.upperStartCamelObject}}
	err := m.QueryRowIndexCtx(ctx, &resp, {{.cacheKeyVariable}}, m.formatPrimary, func(ctx context.Context, conn sqlx.SqlConn, v any) (i any, e error) {
		var query string
		if option.isSoftDelete {
			query = fmt.Sprintf("select %s from %s where {{.originalField}} and deleted_at is null limit 1", {{.lowerStartCamelObject}}Rows, m.table)
		} else {
			query = fmt.Sprintf("select %s from %s where {{.originalField}} limit 1", {{.lowerStartCamelObject}}Rows, m.table)
		}
		if option.session != nil {
			err := option.session.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelField}})
			if err != nil {
				return nil, err
			}
			return resp.{{.upperStartCamelPrimaryKey}}, nil
		}
		err := conn.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelField}})
		if err != nil {
			return nil, err
		}
		return resp.{{.upperStartCamelPrimaryKey}}, nil
	}, m.queryPrimary)
	switch err {
	case nil:
		return &resp, nil
	case sqlc.ErrNotFound:
		return nil, ErrNotFound
	default:
		return nil, err
	}
}{{else}}var resp {{.upperStartCamelObject}}
	var query string
	if option.isSoftDelete {
		query = fmt.Sprintf("select %s from %s where {{.originalField}} and deleted_at is null limit 1", {{.lowerStartCamelObject}}Rows, m.table)
	} else {
		query = fmt.Sprintf("select %s from %s where {{.originalField}} limit 1", {{.lowerStartCamelObject}}Rows, m.table)
	}
	var err error
	if option.session != nil {
		err = option.session.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelField}})
	} else {
		err = m.conn.QueryRowCtx(ctx, &resp, query, {{.lowerStartCamelField}})
	}
	switch err {
	case nil:
		return &resp, nil
	case sqlx.ErrNotFound:
		return nil, ErrNotFound
	default:
		return nil, err
	}
{{end}}
