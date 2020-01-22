FROM golang:1.13

WORKDIR /go/src/main
COPY . .

RUN go get -d -v ./...
RUN go install -v ./...
CMD ["main"]
