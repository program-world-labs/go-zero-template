import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"reflect"
	"slices"
	"strings"
	"time"

	"github.com/ettle/strcase"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/{{if .postgreSql}}postgres{{else}}mysql{{end}}"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	{{if .containsPQ}}"github.com/lib/pq"{{end}}
	"github.com/zeromicro/go-zero/core/stores/builder"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/redis"
	"github.com/zeromicro/go-zero/core/stores/sqlc"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
	"github.com/zeromicro/go-zero/core/stringx"

	{{.third}}
)
