GO111MODULE:=on 
GOBIN:=(go env GOPATH)/bin

install:
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest && \
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2 && \
	go install github.com/bufbuild/buf/cmd/buf@v1.7.0

build_proto: install
	cd proto && buf mod update && buf generate

build_docker: build_proto
	docker-compose build

start_docker: build_docker
	docker-compose up -d

remove_docker:
	docker-compose down --rmi all -v --remove-orphans

# LOGGING

logs_ingestor:
	docker logs opensearch-ingestor -f

logs_opensearch:
	docker logs opensearch-node1 -f

