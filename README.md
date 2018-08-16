# zcp-keycloak intallation guide via Helm

## evn.properties 파일 수정
evn.properties 파일을 편집기로 열어 아래 항목을 프로젝트에 맞게 수정한다.

```
$ vi manifests/evn.properties 
```

```
# target namespace installed
TARGET_NAMESPACE=zcp-system

# keyclaok domain certificate secret name
# 1. 프로젝트에 적용할 인증서로 생성한 secret name 을 입력
DOMAIN_SECRET_NAME=cloudzcp-io-cert

# keycloak user account
KEYCLOAK_ADMIN_ID=cloudzcp-admin
# 2. keycloak 관리자의 비밀번호 입력
KEYCLOAK_ADMIN_PWD=xxxxxxx

# keycloak domain host
# 3. 프로젝트에 적용할 IAM 도메인 정보로 수정하여 입력
KEYCLOAK_INGRESS_HOSTS=iam.cloudzcp.io
KEYCLOAK_INGRESS_TLS_HOSTS=iam.cloudzcp.io

# keycloak resources
KEYCLOAK_LIMIT_CPU=800m
KEYCLOAK_LIMIT_MEM=1024Mi
KEYCLOAK_REQUEST_CPU=200m
KEYCLOAK_REQUEST_MEM=1024Mi

# keycloak db config
KEYCLOAK_DB_VENDOR=POSTGRES
KEYCLOAK_DB_NAME=keycloak
#KEYCLOAK_DB_HOST=zcp-oidc-postgresql
KEYCLOAK_DB_PORT=5432
KEYCLOAK_DB_USER=keycloak
KEYCLOAK_DB_PWD=keycloak!23$
KEYCLOAK_DB_PVC_NAME=zcp-oidc-postgresql
```

## PostgreSQL 생성
### postgresql 디렉토리로 이동
```
$ cd manifests/postgresql
```

### zcp-oidc-postgresql-pvc.yaml 파일 확인 및 수정
실제 프로젝트에 적용할 pvc 는 retain silver 로 해야 함.
```
$ vi zcp-oidc-postgresql-pvc.yaml
```

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    volume.beta.kubernetes.io/storage-class: "ibmc-block-retain-silver"
  labels:
    app: zcp-oidc-postgresql
  name: zcp-oidc-postgresql
  #namespace: zcp-system
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: ibmc-block-retain-silver
```
### pvc 생성
```
$ ./kube_pvc_create.sh
```

dynamic provisioning & bound 되는데 2~10 분 정도 소요될 수 있음.
아래 kubectl 명령어로 bound 되었는지 확인 후 다음 단계 수행

```
$ kubectl get pv
$ kubectl get pvc -n zcp-system
```

### postgresql 생성
values.yaml 을 프로젝트에 맞게 수정
Image Registry 경로를 확인 한다.
Private Only로 클러스터 생성하는 경우 반드시 IBM Container Registry 를 사용해야 함.

```
image: "registry.au-syd.bluemix.net/cloudzcp/postgres"
imageTag: "9.6.2"

tolerations:
  - effect: NoSchedule
    key: management
    operator: Equal
    value: "true"
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: beta.kubernetes.io/arch
          operator: In
          values:
          - amd64
        - key: role
          operator: In
          values:
          - management

metrics:
  image: registry.au-syd.bluemix.net/cloudzcp/postgres_exporter
```

Helm install 수행
```
$ ./helm_install.sh
```

```
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
```

아래 명령어로 postgresql 이 정상적으로 실행되었는지 확인
```
$ kubectl get pod -n zcp-system
```
