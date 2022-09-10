FROM golang:1.19-alpine AS builder
WORKDIR /app
RUN go version
RUN apk update && apk upgrade && \
    apk add --no-cache bash git
# copy Go modules and dependencies to image
COPY go.* ./
# download Go modules and dependencies
RUN go mod download
# copy directory files
COPY ./ ./
# compile application
RUN go build -o /godocker
# command to be used to execute when the image is used to start a container

FROM alpine
COPY --from=builder /godocker /godocker
COPY --from=builder /app/api.swagger.json /api.swagger.json
CMD [ "/godocker" ]