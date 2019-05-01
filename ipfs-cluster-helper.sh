#!/bin/sh

# This is a help script to test IPFS Cluster locally
# This would run a cluster with two peers
# It assumes that you have following softwares installed:
# - IPFS-Cluster
# - Docker
# - jq
# It also assumes that you are using gnome terminal

# Remove all containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Start two IPFS nodes
docker run -d --name ipfs \
  -p 8080:8080 -p 4001:4001 -p 127.0.0.1:5001:5001 \
  ipfs/go-ipfs:latest

docker run -d --name ipfs0 \
  -p 8180:8080 -p 4101:4001 -p 127.0.0.1:5101:5001 \
  ipfs/go-ipfs:latest

# Create a Secret
export CLUSTER_SECRET=$(od  -vN 32 -An -tx1 /dev/urandom | tr -d ' \n')

# Initialize two cluster peers
ipfs-cluster-service init
ipfs-cluster-service -c $HOME/.ipfs-cluster0 init

# Modify service.json for peer 2
jq '.cluster.listen_multiaddress = "/ip4/0.0.0.0/tcp/9196"' ~/.ipfs-cluster0/service.json > tmp.json
mv tmp.json ~/.ipfs-cluster0/service.json
jq '.api.ipfsproxy.listen_multiaddress = "/ip4/127.0.0.1/tcp/9195"' ~/.ipfs-cluster0/service.json > tmp.json
mv tmp.json ~/.ipfs-cluster0/service.json
jq '.api.ipfsproxy.node_multiaddress = "/ip4/127.0.0.1/tcp/5101"' ~/.ipfs-cluster0/service.json > tmp.json
mv tmp.json ~/.ipfs-cluster0/service.json
jq '.api.restapi.http_listen_multiaddress = "/ip4/127.0.0.1/tcp/9194"' ~/.ipfs-cluster0/service.json > tmp.json
mv tmp.json ~/.ipfs-cluster0/service.json
jq '.ipfs_connector.ipfshttp.node_multiaddress = "/ip4/127.0.0.1/tcp/5101"' ~/.ipfs-cluster0/service.json > tmp.json
mv tmp.json ~/.ipfs-cluster0/service.json

# Run ipfs-cluster daemons of two peers
export j=$(cat ~/.ipfs-cluster/service.json | jq -r '.cluster.id')
export k="ipfs-cluster-service -c $HOME/.ipfs-cluster0 daemon --bootstrap /ip4/127.0.0.1/tcp/9096/ipfs/$j"
gnome-terminal --tab -e "ipfs-cluster-service daemon" --tab -e "$k"
