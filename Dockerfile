# ==================== 构建阶段 ====================
FROM golang:1.25-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

# 复制依赖文件并下载
COPY go.mod go.sum ./
RUN go mod download

# 复制全部源码
COPY . .

# 如果 web/public/defaultTheme 不存在，创建一个空目录（避免 embed 报错）
# 如果项目实际需要主题文件，请替换为真实下载/复制命令
RUN mkdir -p web/public/defaultTheme || true

# 编译静态二进制
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o komari .

# ==================== 运行阶段 ====================
FROM alpine:3.21
WORKDIR /app
RUN apk add --no-cache ca-certificates curl tzdata
COPY --from=builder /build/komari /app/komari
RUN chmod +x /app/komari

ENV GIN_MODE=release
ENV KOMARI_LISTEN=0.0.0.0:25774
EXPOSE 25774
CMD ["/app/komari", "server"]
