import (
	"context"
	"database/sql"
	"fmt"
	"slices"
	"reflect"
	"strings"
	"time"

	"github.com/ettle/strcase"
	{{if .containsPQ}}"github.com/lib/pq"{{end}}
	"github.com/zeromicro/go-zero/core/stores/builder"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/redis"
	"github.com/zeromicro/go-zero/core/stores/sqlc"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
	"github.com/zeromicro/go-zero/core/stringx"

	{{.third}}
)
