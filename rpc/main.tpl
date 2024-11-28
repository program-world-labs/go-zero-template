package main

import (
	"flag"

	{{.imports}}
	"bear/libs/pwpkg/consul"
	"bear/libs/pwpkg/middleware/trace"
	"bear/libs/pwpkg/pwlogger"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/core/service"
	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

var configFile = flag.String("f", "etc/{{.serviceName}}.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv())
	ctx := svc.NewServiceContext(c)

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

	logger := pwlogger.NewDLogger(c.Name, c.Env, c.Version)
	s.AddUnaryInterceptors(logger.UnaryServerInterceptor())
	s.AddUnaryInterceptors(trace.TracerInterceptor(c.Name))

	if c.Env == "local" {
		err := consul.RegisterService(c.ListenOn, c.Consul)
		if err != nil {
			logx.Errorf("register service to consul failed: %v", err)
			panic(err)
		}
	}

	logx.Printf("Starting rpc server at %s...\n", c.ListenOn)
	s.Start()
}
