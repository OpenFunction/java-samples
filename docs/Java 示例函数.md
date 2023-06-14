# OpenFunction Java 函数示例

## 环境准备

部署 [OpenFunction](https://openfunction.dev/docs/getting-started/installation/)。

检查 [prerequisites](https://openfunction.dev/docs/getting-started/quickstarts/prerequisites/)。

## 同步函数

### 不使用 output 的同步函数

创建函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/http-function.yaml
```

访问函数

```shell
curl http://function-http-java.default.svc.cluster.local
Hello, World!
```

### 使用 output 的同步函数

创建函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/function-front.yaml
```

访问函数

```shell
curl -d '{"message":"Awesome OpenFunction!"}' -H "Content-Type: application/json" -X POST http://function-front.default.svc.cluster.local/
```

查看函数日志

  ```shell
  kubectl logs -f \
    $(kubectl get po -l \
    openfunction.io/serving=$(kubectl get functions function-front -o jsonpath='{.status.serving.resourceRef}') \
    -o jsonpath='{.items[0].metadata.name}') \
    function
  ```

日志如下

```shell
[main] INFO org.eclipse.jetty.server.Server - jetty-11.0.9; built: 2022-03-30T17:44:47.085Z; git: 243a48a658a183130a8c8de353178d154ca04f04; jvm 18.0.2+9
[main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started o.e.j.s.ServletContextHandler@-3b057770{/,null,AVAILABLE}
[main] INFO org.eclipse.jetty.server.AbstractConnector - Started ServerConnector@3753411{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}
[main] INFO org.eclipse.jetty.server.Server - Started Server@cc0bbf24{STARTING}[11.0.9,sto=0] @4165ms
plugin plugin-example:v1.0.0 exec pre hook for http function at 2023-06-01 08:20:57.Z, seq 1
receive event: {"message":"Awesome OpenFunction!"}
plugin plugin-example:v1.0.0 exec post hook for http function at 2023-06-01 08:20:57.Z, seq 1
```

## Cloudevent 函数

创建函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/cloudevent-function.yaml
```

访问函数

```shell
  curl http://function-cloudevent-java.default.svc.cluster.local \
    -X POST \
    -H "Ce-Specversion: 1.0" \
    -H "Ce-Type: dev.knative.samples.helloworld" \
    -H "Ce-Source: dev.knative.samples/helloworldsource" \
    -H "Ce-Subject: 123" \
    -H "Ce-Id: 536808d3-88be-4077-9d7a-a3f162705f79" \
    -H "Content-Type: application/json" \
    -d '{"data":"hello world"}'
```

查看函数日志

```shell
  kubectl logs -f \
    $(kubectl get po -l \
    openfunction.io/serving=$(kubectl get functions function-cloudevent-java -o jsonpath='{.status.serving.resourceRef}') \
    -o jsonpath='{.items[0].metadata.name}') \
    function
```

日志如下

  ```shell
  [main] INFO org.eclipse.jetty.server.Server - jetty-11.0.9; built: 2022-03-30T17:44:47.085Z; git: 243a48a658a183130a8c8de353178d154ca04f04; jvm 18.0.1.1+2
  [main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started o.e.j.s.ServletContextHandler@64ed162{/,null,AVAILABLE}
  [main] INFO org.eclipse.jetty.server.AbstractConnector - Started ServerConnector@7b929271{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}
  [main] INFO org.eclipse.jetty.server.Server - Started Server@41b1c863{STARTING}[11.0.9,sto=0] @836ms
  receive event: {"data":"hello world"}
  ```

## 异步函数

### 从 kafka 获取数据

该示例需要用到 <a href="#使用-output-的同步函数">使用 output 的同步函数</a>

创建函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/kafka-input.yaml
```

向 `kafka` 中发送数据

```shell
curl -d '{"message":"Awesome OpenFunction!"}' -H "Content-Type: application/json" -X POST http://function-front.default.svc.cluster.local/
```

查看函数日志

```shell
  kubectl logs -f \
    $(kubectl get po -l \
    openfunction.io/serving=$(kubectl get functions kafka-input-java -o jsonpath='{.status.serving.resourceRef}') \
    -o jsonpath='{.items[0].metadata.name}') \
    function
```

日志如下

```shell
  plugin plugin-example:v1.0.0 exec pre hook for binding serving-922d6-component-target-topic-jpvlq at 2022-10-18 09:55:08.Z
  receive event: "{\"message\":\"Awesome OpenFunction!\"}"
  plugin plugin-example:v1.0.0 exec post hook for binding serving-922d6-component-target-topic-jpvlq at 2022-10-18 09:55:08.Z
```

### 定时向 kafka 写入数据

该函数使用 `cron` 组件定时触发，触发后会向 `kafka` 写入数据。

创建函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/cron-input-kafka-output.yaml
```

查看函数日志

```shell
  kubectl logs -f \
    $(kubectl get po -l \
    openfunction.io/serving=$(kubectl get functions kafka-input-java -o jsonpath='{.status.serving.resourceRef}') \
    -o jsonpath='{.items[0].metadata.name}') \
    function
```

日志如下

  ```shell
 plugin plugin-example:v1.0.0 exec pre hook for binding serving-p7nll-component-target-topic-kjh7q at 2022-10-19 08:12:58.Z
 receive event: ""
 plugin plugin-example:v1.0.0 exec post hook for binding serving-p7nll-component-target-topic-kjh7q at 2022-10-19 08:12:58.Z
  ```

### kafka 订阅

该函数通过 `dapr pubsub` 消费 `kafka` 中的数据，函数的工作负载的副本数会自动调整。

创建 producer

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/samples/main/functions/async/pubsub/producer/deploy.yaml
```

创建 subscribe 函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/function-subscriber.yaml
```

## 读取配置

配置文件保存在 configmap 中，用户可以通过访问 function 获取配置。

### 从文件读取配置

configmap 挂载到 function 的 pod 中，function 通过读取文件获取配置，并监听配置文件的变化，实时更新配置

创建 configmap

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  config.yaml: |
    host: 127.0.0.1
    port: 9090
    user: admin
    password: admin
kind: ConfigMap
metadata:
  name: get-config-from-file
  namespace: default
EOF
```

部署 Function

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/get-config-from-file.yaml
```

### 从 configmap 读取配置

function 直接从 configmap 读取配置，k8s 的 informer 机制可以保证配置是实时更新的。

创建 configmap

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  config.yaml: |
    log-level: debug
    log-path: /var/log/openfunction
kind: ConfigMap
metadata:
  name: get-config-from-configmap
  namespace: default
EOF
```

部署 Function

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/get-config-from-configmap.yaml
```

> 访问 k8s 资源需要创建对应的 servingaccount，role 和 rolebinding。

## API 聚合

用户调用函数 A，函数 A 调用函数 B 和 C，聚合函数 B 和 C 的结果，返回给用户。

> 此用例需使用上文定义的两个获取配置的函数。

部署 Function

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/function-aggregation.yaml
```

PS: 需要修改 function 的spec.serving.params 中的 FUNCTIONS 字段的值为实际的 function的访问地址

## Redis state store

通过 Function 访问 redis，使用了 dapr 的 state store。

部署 Function

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/redis-state-store.yaml
```

创建 state

```shell
curl -XPOST -H "Content-Type: application/json" 'http://redis-state-store.default.svc.cluster.local/' -d '

{
  "key1": "value1",
  "key2": "value2",
  "key3": "value3"
}'

save 3 states
```

获取 state

```shell
curl http://redis-state-store.default.svc.cluster.local?key=key1\&key=key2

[
    {
        "value":"value1",
        "key":"key1",
        "etag":"1",
        "metadata":{
        }
    },
    {
        "value":"value2",
        "key":"key2",
        "etag":"1",
        "metadata":{
        }
    }
]
```

删除 state

```shell
curl -XDELETE http://redis-state-store.default.svc.cluster.local?key=key1\&key=key2

delete 2 states
```

## MySQL state store

通过 Function 访问 mysql，使用了 dapr 的 state store。

部署 Function

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/mysql-state-store.yaml
```

创建 state

```shell
curl -XPOST -H "Content-Type: application/json" 'http://mysql-state-store.default.svc.cluster.local/' -d '

{
  "key1": "value1",
  "key2": "value2",
  "key3": "value3"
}'

save 3 states
```

获取 state

```shell
curl http://mysql-state-store.default.svc.cluster.local?key=key1\&key=key2

[
    {
        "value":"value1",
        "key":"key1",
        "etag":"1",
        "metadata":{
        }
    },
    {
        "value":"value2",
        "key":"key2",
        "etag":"1",
        "metadata":{
        }
    }
]
```

删除 state

```shell
curl -XDELETE http://mysql-state-store.default.svc.cluster.local?key=key1\&key=key2

delete 2 states
```

## MySQL to redis

定时从 mysql 读取数据写入 redis，使用 dapr 的 cron 组件定时触发函数，使用 jdbc 读取 mysql 中的数据，通过 dapr state store 写入 redis。

部署 Function

```yaml
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/mysql-to-redis.yaml
```

PS：需要修改 mysql-to-redis.yaml 中以下环境变量

```yaml
JDBC_DRIVER: "com.mysql.cj.jdbc.Driver"
MYSQL_URL: "jdbc:mysql://mysql:3306/?useSSL=false&allowPublicKeyRetrieval=true"
MYSQL_USER: "root"
MYSQL_PASSWORD: "123456"
MYSQL_TABLE: "openfunction.state" // table需提前创建
PRIMARY_KEY: "key"
```

PS：Function 会每 5s 同步一次数据。

向 mysql 插入数据，等待 5s 后通过 redis-state-store 函数查询 state。

插入数据

```
insert into states values ("key1", "value1");
```

查询数据

```yaml
curl http://redis-state-store.default.svc.cluster.local?key=key1

[{"value":{"value":"value1","key":"key1"},"key":"key1","etag":"33","metadata":{}}][
```

## 读写 PVC

函数挂载 pv，用户可以通过调用函数在 pv 中创建文件。本用例主要展示函数如何挂载和操作 pv。

Knative 默认不支持挂载 pvc，需要启用此功能

```yaml
kubectl edit cm -n knative-serving config-features
```

添加

```yaml
data:  
  kubernetes.podspec-persistent-volume-claim: enabled
  kubernetes.podspec-persistent-volume-write: enabled
```

部署函数

```shell
kubectl apply -f https://raw.githubusercontent.com/OpenFunction/java-samples/release-1.0/src/main/resources/functions/file-read-write.yaml
```

创建文件

```shell
curl -XPOST -H "Content-Type: application/json" 'http://file-read-write.default.svc.cluster.local/?name=test' -d '

{
  "name": "test",
  "describe": "This is a test",
  "data": "Hello World"
}'
```

list 文件

```shell
curl http://file-read-write.default.svc.cluster.local/

["test"]
```

获取文件

```shell
curl http://file-read-write.default.svc.cluster.local/?name=test

{"test":"\n\n{\n  \"name\": \"test\",\n  \"describe\": \"This is a test\",\n  \"data\": \"Hello World\"\n}"}
```

删除文件

```shell
curl -XDELETE http://file-read-write.default.svc.cluster.local/?name=test
```


## 使用 cache-image 加速构建

### 修改 strategy

```shell
kubectl edit clusterbuildstrategies.shipwright.io openfunction
```

添加 `cache-image` 参数

```yaml
- args:
  - -app=/workspace/source/$(params.CONTEXT_DIR)
  - -cache-dir=/cache
  - -cache-image=$(params.CACHE_IMAGE)
  - -uid=$(params.USER_ID)
  - -gid=$(params.GROUP_ID)
  - -layers=/layers
  - -platform=/platform
  - -report=/layers/report.toml
  - -process-type=$(params.PROCESS_TYPE)
  - -skip-restore=$(params.SKIP_RESTORE)
  - -previous-image=$(params.shp-output-image)
  - -run-image=$(params.RUN_IMAGE)
  - $(params.shp-output-image)
  command:
  - /cnb/lifecycle/creator
```

### 设置 cache-image

```yaml
apiVersion: core.openfunction.io/v1beta1
kind: Function
metadata:
  name: get-config-from-file
spec:
  build:
    params: 
      CACHE_IMAGE: "openfunctiondev/get-config-from-file-cache:v1"
```

> cache-image 中包含了编译过程中拉取的 maven 依赖，构建镜像时会自动创建并更新 cache-image，下次编译时会自动使用





