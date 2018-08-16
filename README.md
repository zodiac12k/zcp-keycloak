# zcp-keycloak intallation guide via Helm

zcp-keycloak 프로젝트를 local 에 clone 한다.
```
$ git clone https://github.com/cnpst/zcp-keycloak.git
```

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

## PostgreSQL Installation
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
values.yaml 을 프로젝트에 맞게 수정한다.

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
$ cat helm_install.sh
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

```
$ ./helm_install.sh
```

아래 명령어로 postgresql 이 정상적으로 실행되었는지 확인
```
$ kubectl get pod -n zcp-system
```

## KeyCloak Installation
### tls secret 생성
```
$ cd menifests/keycloak
```

Ingress 에 적용할 TLS Secret 을 생성 한다.

TLS Secret 이 이미 생성되어 있는 경우 생략 할 수 있다.

tls-secret.yaml 의 내용을 실제 인증서의 값으로 수정 한다.

metadata.namespace 의 값이 env.properties 의 TARGET_NAMESPACE 와 동일해야 한다.

metadata.name 이 env.properties 의 DOMAIN_SECRET_NAME 과 동일해야 한다.

```
$ vi menifests/keycloak/tls-secret.yaml
```

```
apiVersion: v1
data:
  tls.crt: xxxx
  tls.key: xxxx
kind: Secret
metadata:
  name: cloudzcp-com-cert
  namespace: zcp-system
type: kubernetes.io/tls
```

```
$ ./kube_secret_create_cert.sh
```

다음 명령어로 Secret 이 생성된 것을 확인한다.

```
$ kubectl get secret -n zcp-system
```

### keycloak 생성 시 import 할 zcp realm secret 생성
realm-zcp-export.json 이 import 할 KeyCloak 의 ZCP Realm Template 이다.

KeyCloak 을 배포하면 서버를 기동하면서 ZCP Realm 을 import 한다.

KeyCloak 이 정상 설치 되면 ZCP Realm 이 import 되어 있는 것을 확인 할 수 있다.

KeyCloak 에 관리자로 로그인 한 이후에 각 ZCP Realm 내에 각 client 의 Valid Redirect URIs 를 수정해 주어야만 한다.

```
$ ./kube_secret_create_realm.sh
```
### KeyCloak 생성
values.yaml 을 프로젝트에 맞게 수정한다.
Ingress 설정의 경우 클러스트의 Private ALB를 사용하는 경우 Private ALB ID 설정을 반드시 해야 한다.

```
keycloak:
  tolerations:
    - effect: NoSchedule
      key: management
      operator: Equal
      value: "true"
  image:
    repository: registry.au-syd.bluemix.net/cloudzcp/keycloak

  affinity: |
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

  extraInitContainers: |
    - name: theme-provider
      image: registry.au-syd.bluemix.net/cloudzcp/zcp-keycloak-theme-provider:0.9.3
      imagePullPolicy: Always
      command:
        - sh
      args:
        - -c
        - |
          echo "Copying theme..."
          cp -R /zcp/* /theme
      volumeMounts:
        - name: theme
          mountPath: /theme

  extraVolumeMounts: |
    - name: theme
      mountPath: /opt/jboss/keycloak/themes/zcp
    - name: realm-secret
      mountPath: "/realm/"
      readOnly: true

  extraVolumes: |
    - name: theme
      emptyDir: {}
    - name: realm-secret
      secret:
        secretName: realm-secret

  extraArgs: -Dkeycloak.import=/realm/realm-zcp-export.json

  persistence:
    deployPostgres: false
    dbHost: zcp-oidc-postgresql

  ingress:
    enabled: true
    path: /

    annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      # ingress.kubernetes.io/affinity: cookie
      ingress.bluemix.net/redirect-to-https: "True"
      # 프로젝트의 클러스터에 Private ALB 를 사용해야 할 경우 아래 주석을 해제하고 아래 값을 반드시 private ALB ID 값으로 수정 한다.
      # ingress.bluemix.net/ALB-ID: "private-cr7a9b181c82674f478e461c648c3000da-alb1"
```

Helm install 수행
```
$ cat helm_install.sh
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
```

```
$ ./helm_install.sh
```

아래 명령어를 KeyCloak 이 정상적으로 설치 되었는지 확인 한다.
```
$ kubectl get pod -n zcp-system
```

## 설치 완료 후 KeyCloak 설정
KeyCloak 이 설치 완료 된 이후에 브라우져로 접속, 위에서 설정한 관리자 계정으로 로그인 한다.
Master Realm 의 master-realm client 의 Access Type 을 confidential 로 수정한다.
관련 내용은 MyShare 의 해당 페이지를 참고 한다.
