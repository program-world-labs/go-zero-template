package {{.packageName}}

import (
	"context"

	{{.imports}}
	"bear/libs/pwpkg/pwlogger"
)

type {{.logicName}} struct {
	ctx    context.Context
	svcCtx *svc.ServiceContext
	logger *pwlogger.DLogger
}

func New{{.logicName}}(ctx context.Context,svcCtx *svc.ServiceContext) *{{.logicName}} {
	return &{{.logicName}}{
		ctx:    ctx,
		svcCtx: svcCtx,
		logger: pwlogger.NewDLogger(svcCtx.Config.Name, svcCtx.Config.Env, svcCtx.Config.Version),
	}
}
{{.functions}}
