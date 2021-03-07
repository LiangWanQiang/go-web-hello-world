FROM golang:alpine3.13

WORKDIR /go/src
COPY helloworld.go ./

RUN go install helloworld.go 
EXPOSE 8081

# 使用$GOPATH不能识别，可能是因为在""中，所以使用绝对路径
# CMD ["$GOPATH/bin/helloworld",">>applog.txt","2>&1","&"]
CMD ["/go/bin/helloworld",">>applog.txt","2>&1","&"]
