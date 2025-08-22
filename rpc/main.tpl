package main

import (
	"embed"
	"flag"
	"os"

	{{.imports}}
	"needle/libs/pwpkg/middleware/mid_error"
	"needle/libs/pwpkg/middleware/trace"
	"needle/libs/pwpkg/pwlogger"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/core/service"
	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

var configFile = flag.String("f", "etc/{{.serviceName}}.yaml", "the config file")

//go:embed internal/i18n/locales/*.json
var translationsFS embed.FS

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv())
	ctx, err := svc.NewServiceContext(c)
	if err != nil {
		logx.Errorf("Failed to create service context: %v", err)
		os.Exit(1)
	}

	if c.Env != "local" {
		tracer.Start()
		defer tracer.Stop()
	}

	s := zrpc.MustNewServer(c.RpcServerConf, func(grpcServer *grpc.Server) {
{{range .serviceNames}}       {{.Pkg}}.Register{{.GRPCService}}Server(grpcServer, {{.ServerPkg}}.New{{.Service}}Server(ctx))
{{end}}
		if c.Mode == service.DevMode || c.Mode == service.TestMode {
			reflection.Register(grpcServer)
		}
	})
	defer s.Stop()

	// ===== 統一國際化錯誤處理配置 (go-i18n) =====
	i18nConfig := &mid_error.I18nConfiguration{
		DefaultLocale:    "zh-TW",                       // 預設繁體中文
		SupportedLocales: []string{"zh-TW", "zh", "en"}, // 支援語言清單：繁中 > 簡中 > 英文
		EmbeddedFS:       translationsFS,                // 嵌入的翻譯文件系統
		BaseDir:          "internal/i18n/locales",       // 翻譯文件基礎目錄 (go-i18n 格式)
	}
	// 設定全域 go-i18n 配置
	mid_error.SetI18nConfiguration(i18nConfig)

	// 創建錯誤攔截器，配置為回退到全域 i18n 管理器（使用嵌入檔案）
	errorInterceptor, err := mid_error.NewErrorInterceptorWithConfig(&mid_error.InterceptorConfig{
		DefaultLocale:     i18nConfig.DefaultLocale,    // 引用統一的預設語言
		SupportedLocales:  i18nConfig.SupportedLocales, // 引用統一的支援語言清單
		FallbackToBuiltin: true,                        // 啟用內建翻譯回退機制
	})
	if err != nil {
		logx.Errorf("Failed to create error interceptor: %v", err)
	}
	// ===== 優化版：統一添加中間件（推薦順序） =====
	logger := pwlogger.NewDLogger(c.Name, c.Env, c.Version)
	s.AddUnaryInterceptors(
		logger.UnaryServerInterceptor(), // 1. 日誌記錄（最外層）
		trace.TracerInterceptor(c.Name), // 2. 追蹤監控（中間層）
		errorInterceptor,                // 3. 錯誤處理（最內層）
	)

	logx.Infof("Starting rpc server at %s...\n", c.ListenOn)
	s.Start()
}
