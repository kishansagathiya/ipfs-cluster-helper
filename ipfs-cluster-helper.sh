#!/usr/bin/env sh

# This is a help script to test IPFS Cluster locally
# This would run a cluster with two peers
# It assumes that you have following softwares installed:
# - IPFS-Cluster
# - Docker
# - jq
# It also assumes that you are using gnome terminal

configure_ipfs () {
    IPFS0=ipfs-0
    IPFS1=ipfs-1
}

configure_cluster () {
    CLUSTER0_CONF=$HOME/.ipfs-cluster-0
    CLUSTER1_CONF=$HOME/.ipfs-cluster-1

    # Create a Secret
    export CLUSTER_SECRET=$(od  -vN 32 -An -tx1 /dev/urandom | tr -d ' \n')

    # Initialize two cluster peers
    ipfs-cluster-service -c $CLUSTER0_CONF init
    ipfs-cluster-service -c $CLUSTER1_CONF init

    # Modify service.json for peers
    jq '.cluster.listen_multiaddress = "/ip4/0.0.0.0/tcp/9196"' $CLUSTER0_CONF/service.json | sponge $CLUSTER0_CONF/service.json
    jq '.api.ipfsproxy.listen_multiaddress = "/ip4/127.0.0.1/tcp/9195"' $CLUSTER0_CONF/service.json | sponge $CLUSTER0_CONF/service.json
    jq '.api.ipfsproxy.node_multiaddress = "/ip4/127.0.0.1/tcp/5101"' $CLUSTER0_CONF/service.json | sponge $CLUSTER0_CONF/service.json
    jq '.api.restapi.http_listen_multiaddress = "/ip4/127.0.0.1/tcp/9194"'  $CLUSTER0_CONF/service.json | sponge $CLUSTER0_CONF/service.json
    jq '.ipfs_connector.ipfshttp.node_multiaddress = "/ip4/127.0.0.1/tcp/5101"'  $CLUSTER0_CONF/service.json | sponge $CLUSTER0_CONF/service.json

    jq '.cluster.listen_multiaddress = "/ip4/0.0.0.0/tcp/9296"' $CLUSTER1_CONF/service.json | sponge $CLUSTER1_CONF/service.json
    jq '.api.ipfsproxy.listen_multiaddress = "/ip4/127.0.0.1/tcp/9295"' $CLUSTER1_CONF/service.json | sponge $CLUSTER1_CONF/service.json
    jq '.api.ipfsproxy.node_multiaddress = "/ip4/127.0.0.1/tcp/5201"' $CLUSTER1_CONF/service.json | sponge $CLUSTER1_CONF/service.json
    jq '.api.restapi.http_listen_multiaddress = "/ip4/127.0.0.1/tcp/9294"'  $CLUSTER1_CONF/service.json | sponge $CLUSTER1_CONF/service.json
    jq '.ipfs_connector.ipfshttp.node_multiaddress = "/ip4/127.0.0.1/tcp/5201"'  $CLUSTER1_CONF/service.json | sponge $CLUSTER1_CONF/service.json
}

cleanup_ipfs () {
    # Remove ipfs containers
    docker rm -f $IPFS0
    docker rm -f $IPFS1
}

start_ipfs () {
    # Start two IPFS nodes
    docker run -d --name ipfs-0 \
      -p 8180:8080 -p 4101:4001 -p 127.0.0.1:5101:5001 \
      ipfs/go-ipfs:latest

    docker run -d --name ipfs-1 \
      -p 8280:8080 -p 4201:4001 -p 127.0.0.1:5201:5001 \
      ipfs/go-ipfs:latest
}

start_cluster () {
    # Run ipfs-cluster daemons of two peers
    clstr0_maddr=$(cat $CLUSTER0_CONF/service.json | jq -r '.cluster.listen_multiaddress')
    clstr0_id=$(cat $CLUSTER0_CONF/service.json | jq -r '.cluster.id')
    export clstr0_exec="ipfs-cluster-service -c $CLUSTER0_CONF daemon"
    export clstr1_exec="ipfs-cluster-service -c $CLUSTER1_CONF daemon --bootstrap $clstr0_maddr/ipfs/$clstr0_id"
    case $TERMINAL in
        "termite")
            termite -e "$clstr0_exec" &
            termite -e "$clstr1_exec" &
            ;;
        *)
            gnome-terminal --tab -e "$clstr0_exec" --tab -e "$clstr1_exec"
            ;;
    esac
}

main () {
    case $1 in
        "cleanup")
            echo "Stopping and removing IPFS docker containers..."
            configure_ipfs
            cleanup_ipfs
            ;;
        *)
            configure_ipfs
            configure_cluster
            cleanup_ipfs
            start_ipfs
            start_cluster
            ;;
    esac
}

main $@
