FROM golang:1.16-alpine

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o server . && adduser -D appuser

ENV REQUEST_ORIGIN=http://localhost:5000

EXPOSE 8080

USER appuser

CMD ["./server"]