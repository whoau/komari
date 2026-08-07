# ==================== 构建阶段 ====================
FROM golang:1.25-alpine AS builder

# 安装必要工具：git（克隆前端）、nodejs 和 npm（构建前端）
RUN apk add --no-cache git nodejs npm

# 接收目标平台参数（默认为 linux/amd64）
ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

# ---------- 1. 准备 Go 后端 ----------
# 先复制依赖文件以利用缓存
COPY go.mod go.sum ./
RUN go mod download

# 复制后端全部源码
COPY . .

# ---------- 2. 获取并构建前端主题 ----------
# 克隆前端仓库（官方 Komari 前端）
RUN git clone https://github.com/komari-monitor/komari-web.git /tmp/komari-web && \
    cd /tmp/komari-web && \
    npm install && \
    npm run build && \
    # 创建后端需要的主题目录，并复制整个 dist 目录（包含所有静态资源）
    mkdir -p web/public/defaultTheme && \
    cp -r /tmp/komari-web/dist web/public/defaultTheme/ && \
    # 如果存在主题配置文件也一并复制（可能不存在，忽略错误）
    cp /tmp/komari-web/komari-theme.json web/public/defaultTheme/ 2>/dev/null || true

# ---------- 3. 编译 Go 二进制 ----------
# 禁用 CGO，生成静态可执行文件
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o komari .

# ==================== 运行阶段 ====================
FROM alpine:3.21

# 安装运行时依赖
RUN apk add --no-cache ca-certificates curl tzdata

WORKDIR /app

# 从构建阶段复制编译好的二进制
COPY --from=builder /build/komari /app/komari
RUN chmod +x /app/komari

# 设置环境变量
ENV GIN_MODE=release
ENV KOMARI_LISTEN=0.0.0.0:25774

EXPOSE 25774

CMD ["/app/komari", "server"]
