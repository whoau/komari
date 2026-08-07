# 阶段1：构建（使用 Go 1.25）
FROM golang:1.25-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o komari .

# 阶段2：运行
FROM alpine:3.21
WORKDIR /app
RUN apk add --no-cache ca-certificates curl tzdata
COPY --from=builder /build/komari /app/komari
RUN chmod +x /app/komari

ENV GIN_MODE=release
ENV KOMARI_LISTEN=0.0.0.0:25774
EXPOSE 25774
CMD ["/app/komari", "server"]
