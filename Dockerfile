# ==================== 构建阶段 ====================
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git nodejs npm

WORKDIR /build

# 下载 Go 依赖
COPY go.mod go.sum ./
RUN go mod download

# 复制源码
COPY . .

# ==================== 构建前端主题 ====================
RUN git clone https://github.com/komari-monitor/komari-web.git /tmp/komari-web && \
    cd /tmp/komari-web && \
    npm install && \
    npm run build && \
    mkdir -p /build/web/public/defaultTheme && \
    cp -r /tmp/komari-web/dist/* /build/web/public/defaultTheme/ && \
    cp /tmp/komari-web/komari-theme.json /build/web/public/defaultTheme/ 2>/dev/null || true

# 检查 embed 文件是否存在
RUN ls -la /build/web/public && \
    ls -la /build/web/public/defaultTheme


# ==================== 编译 Go ====================
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -o komari .


# ==================== 运行阶段 ====================
FROM alpine:3.21

RUN apk add --no-cache ca-certificates curl tzdata

WORKDIR /app

COPY --from=builder /build/komari /app/komari

EXPOSE 25774

ENTRYPOINT ["/app/komari"]
