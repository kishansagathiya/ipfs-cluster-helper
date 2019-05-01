# ipfs-cluster-helper
Shell script to start IPFS Cluster with two peers

This script would 
- create two IPFS nodes, 
- initialize two cluster nodes, 
- make sure that both cluster nodes are using different ports
- make sure that both cluster nodes are using the same secret
- run `daemon` for each cluster node in a different tab
