# 阶段1：构建
FROM golang:1.21-alpine AS builder

# 接收平台参数（可选，用于交叉编译）
ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

# 先复制依赖文件，利用 Docker 缓存加速
COPY go.mod go.sum ./
RUN go mod download

# 复制全部源代码
COPY . .

# 编译静态可执行文件（禁用 CGO 以保证跨平台兼容）
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o komari .

# 阶段2：运行
FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache ca-certificates curl tzdata

# 从构建阶段复制编译好的二进制
COPY --from=builder /build/komari /app/komari

RUN chmod +x /app/komari

ENV GIN_MODE=release
ENV KOMARI_LISTEN=0.0.0.0:25774

EXPOSE 25774

CMD ["/app/komari", "server"]
