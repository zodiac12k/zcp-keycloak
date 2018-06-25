helm install stable/postgresql --version 0.12.0 \
--name zcp-oidc-postgresql \
-f values.yaml \
--namespace zcp-oidc \
--set postgresUser=keycloak \
--set postgresPassword=keycloak1234! \
--set postgresDatabase=keycloak \
--set persistence.enabled=true \
--set persistence.storageClass=ibmc-block-bronze \
--set persistence.size=20Gi \
--set metrics.enabled=true 
#--set persistence.existingClaim=zcp-oidc-postgresql
