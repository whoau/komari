# ==================== 构建阶段 ====================
FROM golang:1.25-alpine AS builder

# 安装 Node.js 和 npm（用于构建前端）
RUN apk add --no-cache nodejs npm

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

# ---------- 1. 构建前端 ----------
# 假设前端代码位于 web/ 目录，使用 npm 构建
COPY web/package*.json web/
WORKDIR /build/web
RUN npm install
COPY web/ .
# 请根据项目实际构建命令调整，例如 `npm run build` 或 `npm run build:web`
# 构建产物通常输出到 web/public/defaultTheme（或 web/dist 等）
RUN npm run build

# ---------- 2. 构建 Go 后端 ----------
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# 确保前端构建产物已经存在（通常位于 web/public/defaultTheme）
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
