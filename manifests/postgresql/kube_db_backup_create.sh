. ../env.properties

kubectl create -f zcp-oidc-postgresql-backup-configmap.yaml -n ${TARGET_NAMESPACE}
kubectl create -f zcp-oidc-postgresql-backup-cronjob.yaml -n ${TARGET_NAMESPACE}

