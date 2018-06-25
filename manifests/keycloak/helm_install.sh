helm install stable/keycloak --version 2.0.0 \
--name zcp-oidc-keycloak \
-f values.yaml \
--namespace zcp-oidc \
--set keycloak.password=keycloak1234!

