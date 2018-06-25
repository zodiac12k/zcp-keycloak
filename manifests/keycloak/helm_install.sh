. ../env.properties

helm install stable/keycloak --version 2.0.0 \
--name zcp-oidc-keycloak \
-f values.yaml \
--namespace ${TARGET_NAMESPACE} \
--set keycloak.username=${KEYCLOAK_ADMIN_ID} \
--set keycloak.password=${KEYCLOAK_ADMIN_PWD} \
--set keycloak.ingress.hosts[0]=${KEYCLOAK_INGRESS_HOSTS} \
--set keycloak.ingress.tls[0].hosts[0]=${KEYCLOAK_INGRESS_HOSTS} \
--set keycloak.ingress.tls[0].secretName=${DOMAIN_SECRET_NAME} \
--set keycloak.persistence.dbVendor=${KEYCLOAK_DB_VENDOR} \
--set keycloak.persistence.dbName=${KEYCLOAK_DB_NAME} \
--set keycloak.persistence.dbPort=${KEYCLOAK_DB_PORT} \
--set keycloak.persistence.dbUser=${KEYCLOAK_DB_USER} \
--set keycloak.persistence.dbPassword=${KEYCLOAK_DB_PWD} \
--set keycloak.resources.limits.cpu=${KEYCLOAK_LIMIT_CPU} \
--set keycloak.resources.limits.memory=${KEYCLOAK_LIMIT_MEM} \
--set keycloak.resources.requests.cpu=${KEYCLOAK_REQUEST_CPU} \
--set keycloak.resources.requests.memory=${KEYCLOAK_REQUEST_MEM}
