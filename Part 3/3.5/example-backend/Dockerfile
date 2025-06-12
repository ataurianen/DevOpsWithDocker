FROM golang:1.16

WORKDIR /app

COPY . .
ENV REQUEST_ORIGIN=http://localhost:5000
RUN go build

EXPOSE 8080

RUN adduser appuser

RUN chown appuser .

USER appuser

CMD ["./server"]