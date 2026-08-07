FROM node:20-alpine AS frontend

RUN apk add --no-cache git
WORKDIR /frontend

RUN git clone --depth=1 https://github.com/komari-monitor/komari-web.git .
RUN npm install
RUN npm run build


FROM golang:1.25-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN mkdir -p web/public/defaultTheme/dist

COPY --from=frontend /frontend/dist/ /build/web/public/defaultTheme/dist/
COPY --from=frontend /frontend/komari-theme.json /build/web/public/defaultTheme/komari-theme.json

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o komari .


FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache ca-certificates curl tzdata

COPY --from=builder /build/komari /app/komari

EXPOSE 25774

VOLUME ["/app/data"]

CMD ["/app/komari", "server", "-l", "0.0.0.0:25774"]
