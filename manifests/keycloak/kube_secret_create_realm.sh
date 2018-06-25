. ../env.properties

kubectl create secret generic realm-secret -n ${TARGET_NAMESPACE} --from-file=realm-zcp-export.json
