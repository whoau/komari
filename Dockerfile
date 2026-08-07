# ==================== 构建阶段 ====================
FROM golang:1.25-alpine AS builder

# 安装编译所需工具（git、nodejs、npm、gcc、musl-dev）
RUN apk add --no-cache git nodejs npm gcc musl-dev

# 接收目标平台参数（默认为 linux/amd64）
ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

# ---------- 1. 准备 Go 后端 ----------
# 复制依赖文件
COPY go.mod go.sum ./

# 强制指定 go-sqlite3 兼容版本（v1.14.19）
RUN go mod edit -require=github.com/mattn/go-sqlite3@v1.14.19 && \
    go mod tidy

# 下载依赖
RUN go mod download

# 复制全部源代码
COPY . .

# ---------- 2. 获取并构建前端主题 ----------
RUN git clone https://github.com/komari-monitor/komari-web.git /tmp/komari-web && \
    cd /tmp/komari-web && \
    npm install && \
    npm run build && \
    mkdir -p /build/web/public/defaultTheme && \
    cp -r /tmp/komari-web/dist/* /build/web/public/defaultTheme/ && \
    cp /tmp/komari-web/komari-theme.json /build/web/public/defaultTheme/ 2>/dev/null || true

# ---------- 3. 编译 Go 二进制（启用 CGO） ----------
RUN CGO_ENABLED=1 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -o komari .

# ==================== 运行阶段 ====================
FROM alpine:3.21

RUN apk add --no-cache ca-certificates curl tzdata

WORKDIR /app

COPY --from=builder /build/komari /app/komari
RUN chmod +x /app/komari

ENV GIN_MODE=release
ENV KOMARI_LISTEN=0.0.0.0:25774

EXPOSE 25774

CMD ["/app/komari", "server"]
