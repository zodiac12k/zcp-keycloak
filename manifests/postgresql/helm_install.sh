. ../env.properties

helm install stable/postgresql --version 0.12.0 \
--name zcp-oidc-postgresql \
-f values.yaml \
--namespace ${TARGET_NAMESPACE} \
--set postgresUser=${KEYCLOAK_DB_USER} \
--set postgresPassword=${KEYCLOAK_DB_PWD} \
--set postgresDatabase=${KEYCLOAK_DB_NAME} \
--set persistence.enabled=true \
--set metrics.enabled=true \
--set persistence.existingClaim=${KEYCLOAK_DB_PVC_NAME}

#--set persistence.storageClass=ibmc-block-bronze \
#--set persistence.size=20Gi \
