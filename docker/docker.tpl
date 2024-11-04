FROM --platform=$BUILDPLATFORM 590183828335.dkr.ecr.ap-southeast-1.amazonaws.com/dockerhub/library/golang:{{.Version}}alpine3.20 AS builder

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

RUN apk update --no-cache && apk add --no-cache tzdata git

WORKDIR /build

COPY ./apps ./apps
COPY ./libs ./libs
COPY ./go.work .
COPY ./go.work.sum .

COPY ./apps/dist/go /app
COPY ./apps/${APP_PATH}/{{.ExeFile}}/etc/{{.ExeFile}}.${APP_ENV}.yaml /app/etc/{{.ExeFile}}.yaml
COPY ./resources/lang /app/resources/lang
COPY ./resources/static /app/resources/static
COPY ./resources/db/{{.ExeFile}} /app/resources/db/{{.ExeFile}}

RUN echo "Building for TARGETPLATFORM=${TARGETPLATFORM}, TARGETARCH=${TARGETARCH}" && \
    if [ -f /app/{{.ExeFile}}_${TARGETOS}_${TARGETARCH} ]; then \
    echo "{{.ExeFile}} exists for ${TARGETARCH}"; \
    mv /app/{{.ExeFile}}_${TARGETOS}_${TARGETARCH} /app/{{.ExeFile}}; \
    else \
    echo "Building {{.ExeFile}} for ${TARGETARCH}"; \
    cd ./apps/${APP_PATH}/{{.ExeFile}} \
    go work sync; \
    go mod tidy; \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w" -o /app/{{.ExeFile}} {{.GoMainFrom}}; \
    fi


FROM 590183828335.dkr.ecr.ap-southeast-1.amazonaws.com/dockerhub/library/{{.BaseImage}}

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
