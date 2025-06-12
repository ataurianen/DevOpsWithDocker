FROM golang:1.16

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build && adduser appuser

ENV REQUEST_ORIGIN=http://localhost:5000

EXPOSE 8080

USER appuser

CMD ["./server"]