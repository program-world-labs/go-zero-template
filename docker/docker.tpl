FROM --platform=$BUILDPLATFORM golang:{{.Version}}-alpine3.20 AS builder

LABEL stage=gobuilder

ENV CGO_ENABLED 0
ARG TARGETOS
ARG TARGETARCH
ARG APP_ENV
ENV APP_ENV=$APP_ENV
ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION
ARG APP_PATH
ENV APP_PATH=$APP_PATH
ARG APP_TYPE
ENV APP_TYPE=$APP_TYPE

RUN apk update --no-cache && apk add --no-cache tzdata git

WORKDIR /build

COPY ./apps ./apps
COPY ./libs ./libs
COPY ./go.work .
COPY ./go.work.sum .

COPY ./apps/dist/go/{{.ExeFile}}_${APP_TYPE}_${TARGETOS}_${TARGETARCH} /app/{{.ExeFile}}
COPY ./apps/${APP_PATH}/{{.ExeFile}}/etc/{{.ExeFile}}.${APP_ENV}.${APP_TYPE}.yaml /app/etc/{{.ExeFile}}.yaml
COPY ./resources/lang /app/resources/lang
COPY ./resources/static /app/resources/static
COPY ./resources/db /app/resources/db
COPY ./libs/protoc/event /app/resources/event
RUN echo "Building for TARGETOS=${TARGETOS}, TARGETARCH=${TARGETARCH}" && \
    if [ -f /app/{{.ExeFile}}_${APP_TYPE}_${TARGETOS}_${TARGETARCH} ]; then \
    echo "{{.ExeFile}} exists for ${TARGETOS} ${TARGETARCH} ${APP_TYPE}"; \
    mv /app/{{.ExeFile}}_${APP_TYPE}_${TARGETOS}_${TARGETARCH} /app/{{.ExeFile}}; \
    else \
    echo "does not exist from /app/{{.ExeFile}}_${APP_TYPE}_${TARGETOS}_${TARGETARCH}"; \
    echo "Building {{.ExeFile}} for ${TARGETOS} ${TARGETARCH} ${APP_TYPE}"; \
    cd ./apps/${APP_PATH}/{{.ExeFile}} \
    go work sync; \
    go mod tidy; \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w" -o /app/{{.ExeFile}} {{.GoMainFrom}}; \
    fi


FROM {{.BaseImage}}

{{if .HasTimezone}}COPY --from=builder /usr/share/zoneinfo/{{.Timezone}} /usr/share/zoneinfo/{{.Timezone}}
ENV TZ {{.Timezone}}
{{end}}
ARG APP_ENV
ENV APP_ENV=$APP_ENV
ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

WORKDIR /app
COPY --from=builder /app/{{.ExeFile}} /app/{{.ExeFile}}{{if .Argument}}
COPY --from=builder /app/etc /app/etc{{end}}
COPY --from=builder /app/resources /app/resources
{{if .HasPort}}
EXPOSE {{.Port}}
{{end}}
CMD ["./{{.ExeFile}}", "-f", "etc/{{.ExeFile}}.yaml"]
