helm upgrade zcp-oidc-keycloak stable/keycloak \
-f values.yaml \
--namespace zcp-oidc \
--set keycloak.password=keycloak1234!

