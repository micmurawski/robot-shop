FROM golang:1.21

WORKDIR /go/src/app

COPY go.mod .
COPY *.go .

RUN go mod download && go mod tidy
RUN go install

CMD ["dispatch"]
