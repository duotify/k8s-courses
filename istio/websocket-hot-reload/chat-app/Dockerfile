# Build

FROM golang:1.14 AS build
WORKDIR /go/src/main
COPY . .
RUN go get -d ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -o app .

# Runtime

FROM curlimages/curl:latest AS runtime
COPY --from=build /go/src/main/app .
COPY --from=build /go/src/main/home.html .
EXPOSE 8080
ENTRYPOINT ["./app"]
