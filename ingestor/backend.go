package main

import (
	"bufio"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"github.com/opensearch-project/opensearch-go"
	"github.com/opensearch-project/opensearch-go/opensearchapi"
	log "github.com/sirupsen/logrus"
	"github.com/unlockprogramming/index-data-in-opensearch-using-go-client/pb"
	"golang.org/x/net/context"
)

type IngestorService struct {
	pb.UnimplementedIngestorServer
	opensearchClient *opensearch.Client
}

func indexIntoOpensearch(opensearchClient *opensearch.Client, record []byte) error {
	var jsonObj interface{}
	err := json.Unmarshal(record, &jsonObj)
	if err != nil {
		return err
	}
	content := string(record)

	log.Debugf("Opensearch indexing: %s", content)

	req := opensearchapi.IndexRequest{}
	req.Index = "ingestors"
	req.Body = strings.NewReader(content)
	resp, err := req.Do(context.Background(), opensearchClient)
	if err != nil {
		return err
	}

	if resp.StatusCode/100 != 2 {
		scanner := bufio.NewScanner(io.LimitReader(resp.Body, 100))
		line := ""
		if scanner.Scan() {
			line = scanner.Text()
		}
		return fmt.Errorf("ingestion status %s (%d): %s", resp.Status, resp.StatusCode, line)
	}

	log.Debugf("Opensearch indexing finished: %s", content)

	return nil

}

func (sr IngestorService) IndexJson(ctx context.Context, in *pb.IndexRequest) (*pb.Response, error) {
	log.Debugf("---Opensearch: IndexJson--")
	content, err := base64.StdEncoding.DecodeString(in.GetContent())
	if err != nil {
		return badRequest(err)
	}
	err = indexIntoOpensearch(sr.opensearchClient, content)
	if err != nil {
		return badRequest(err)
	}
	return &pb.Response{Status: "200", Message: "Successfully published"}, nil
}

func badRequest(err error) (*pb.Response, error) {
	message := fmt.Sprintf("Bad input: %v", err)
	log.Errorf(message)
	return &pb.Response{Status: "400", Message: message}, nil
}
