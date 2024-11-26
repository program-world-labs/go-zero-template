package {{.packageName}}

import (
	"context"

	{{.imports}}

	"needle/libs/pwpkg/pwlogger"
)

type {{.logicName}} struct {
	ctx    context.Context
	svcCtx *svc.ServiceContext
	logx.Logger
}

func New{{.logicName}}(ctx context.Context,svcCtx *svc.ServiceContext) *{{.logicName}} {
	return &{{.logicName}}{
		ctx:    ctx,
		svcCtx: svcCtx,
		Logger: pwlogger.InitLoggerWithContext(ctx),
	}
}
{{.functions}}
