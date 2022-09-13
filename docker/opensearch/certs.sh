#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -e

rm -rf "$SCRIPT_DIR/build/" && mkdir -p "$SCRIPT_DIR/build/"
cd "$SCRIPT_DIR/build/"

SUBJECT_PREFIX="/C=CA/ST=ONTARIO/L=TORONTO/O=ORG/OU=UNIT"
# Root CA
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "$SUBJECT/CN=opensearch-cluster-root" -out root-ca.pem -days 730
# Admin cert
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -subj "$SUBJECT_PREFIX/CN=opensearch-cluster-admin" -out admin.csr
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730
# Node cert 1
openssl genrsa -out node1-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node1-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node1-key.pem
openssl req -new -key node1-key.pem -subj "$SUBJECT_PREFIX/CN=opensearch-cluster-master" -out node1.csr
echo "subjectAltName=DNS:opensearch-cluster-master" > node1.ext
openssl x509 -req -in node1.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node1.pem -days 730 -extfile node1.ext
# Node cert 2
openssl genrsa -out node2-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node2-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node2-key.pem
openssl req -new -key node2-key.pem -subj "$SUBJECT_PREFIX/CN=opensearch-cluster-data" -out node2.csr
echo "subjectAltName=DNS:opensearch-cluster-data" > node2.ext
openssl x509 -req -in node2.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node2.pem -days 730 -extfile node2.ext
# Client cert
openssl genrsa -out client-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in client-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out client-key.pem
openssl req -new -key client-key.pem -subj "$SUBJECT_PREFIX/CN=opensearch-cluster-dashboard" -out client.csr
echo "subjectAltName=DNS:opensearch-cluster-dashboard" > client.ext
openssl x509 -req -in client.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out client.pem -days 730 -extfile client.ext
# Consumer cert
openssl genrsa -out consumer-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in consumer-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out consumer-key.pem
openssl req -new -key consumer-key.pem -subj "$SUBJECT_PREFIX/CN=opensearch-cluster-consumer" -out consumer.csr
echo "subjectAltName=DNS:opensearch-cluster-consumer" > consumer.ext
openssl x509 -req -in consumer.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out consumer.pem -days 730 -extfile consumer.ext
# Cleanup
rm admin-key-temp.pem
rm admin.csr
rm node1-key-temp.pem
rm node1.csr
rm node1.ext
rm client-key-temp.pem
rm client.csr
rm client.ext
rm consumer-key-temp.pem
rm consumer.csr
rm consumer.ext