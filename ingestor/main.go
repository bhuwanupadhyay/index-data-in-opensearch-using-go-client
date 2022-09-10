package main

import (
	"context"
	"flag"
	"fmt"
	"net"
	"os"

	"github.com/opensearch-project/opensearch-go"
	log "github.com/sirupsen/logrus"
	"github.com/unlockprogramming/index-data-in-opensearch-using-go-client/pb"
	"google.golang.org/grpc"
)

var (
	appName       = os.Getenv("APP_NAME")
	logLevel      = os.Getenv("LOG_LEVEL")
	opensearchUrl = os.Getenv("OPENSEARCH_URL")
)

func setupArguments() {
	flag.Parse()

	if len(logLevel) == 0 {
		logLevel = "debug"
	}

}

func getOpensearchClient() *opensearch.Client {
	opensearchClient, err := opensearch.NewClient(opensearch.Config{
		Addresses: []string{opensearchUrl},
	})
	if err != nil {
		log.Errorf("Error during opensearch client configuration: %v", err)
	}
	// info, err := opensearchClient.Info()
	// if err != nil {
	// 	panic(err)
	// }
	// log.Infof("OpenSearch client connection status: %v", info.Status())
	// if info.IsError() {
	// 	panic(info)
	// }
	return opensearchClient
}

func main() {
	setupArguments()

	// Log as JSON instead of the default ASCII formatter.
	log.SetFormatter(&log.JSONFormatter{})
	log.SetOutput(os.Stdout)
	level, _ := log.ParseLevel(logLevel)
	log.SetLevel(level)

	grpcAddr := fmt.Sprintf(":%d", 8086)
	proxyAddr := fmt.Sprintf("0.0.0.0:%d", 8080)

	opensearchClient := getOpensearchClient()

	grpcServer := grpc.NewServer()
	pb.RegisterIngestorServer(grpcServer, &IngestorService{
		opensearchClient: opensearchClient,
	})

	// Start your http server for healthcheck.
	go func() {
		err := gatewayProxy(context.TODO(), Options{
			GRPCServer: Endpoint{Addr: grpcAddr, Network: "tcp"},
			OpenAPIDir: "/",
			Addr:       proxyAddr,
		})
		if err != nil {
			log.Fatalf("%s: failed to serve proxy: %v", appName, err)
		}
	}()

	lis, err := net.Listen("tcp", grpcAddr)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Infof("%s: listening grpc at %v", appName, lis.Addr())
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("%s: failed to serve: %v", appName, err)
	}
}
