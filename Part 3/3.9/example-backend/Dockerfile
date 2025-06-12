FROM golang:1.16-alpine AS builder

WORKDIR /app

ENV CGO_ENABLED=0

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o server -ldflags "-s -w" .

FROM scratch

WORKDIR /app

COPY --from=builder /app/server ./server

ENV REQUEST_ORIGIN=http://localhost:5000

EXPOSE 8080

USER 65532

CMD ["./server"]