minikube start --driver kvm2 --memory 20g --cpus 8 --disk-size 200g

sleep 10

for i in ./*.yaml; do kubectl apply -f $i; done

helm -n ntwk-mainnet-fullnode install secrets-creator filecoin/lotus-secrets-creator --set secrets.jwt.secretName=fullnode-0-jwt-secrets --set secrets.jwt.enabled=true --set secrets.libp2p.secretName=fullnode-0-libp2p-secrets --set secrets.libp2p.enabled=true

#minikube mount ~/minikube-shared:/tmp/hostpath-provisioner/ --ip 192.168.39.1 --9p-version=9p2000.L
