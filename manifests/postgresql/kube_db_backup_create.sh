. ../env.properties

kubectl create -f backup-configmap.yaml -n ${TARGET_NAMESPACE}
kubectl create -f backup-cronjob.yaml -n ${TARGET_NAMESPACE}

