FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

# Собираем проект
RUN go build -o web ./cmd/web

FROM alpine:3.18

WORKDIR /app

# Устанавливаем bash
RUN apk add --no-cache bash netcat-openbsd

COPY --from=builder /app/web .

# Копируем скрипт wait-for-it.sh
COPY wait-for-it.sh .

# Делаем скрипт исполняемым
RUN chmod +x wait-for-it.sh

# Копируем TLS-сертификаты
COPY tls/ ./tls/

# Порт, который будет прослушивать контейнер
EXPOSE 8080

# Команда запуска приложения через wait-for-it.sh
CMD ["./wait-for-it.sh", "mysql:3306", "--", "./web"]