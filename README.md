# Домашнее задание к занятию 5. «Elasticsearch», Лебедев А.И., FOPS-10

## Задача 1

В этом задании вы потренируетесь в:

- установке Elasticsearch,
- первоначальном конфигурировании Elasticsearch,
- запуске Elasticsearch в Docker.

Используя Docker-образ [centos:7](https://hub.docker.com/_/centos) как базовый и 
[документацию по установке и запуску Elastcisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html):

- составьте Dockerfile-манифест для Elasticsearch,
- соберите Docker-образ и сделайте `push` в ваш docker.io-репозиторий,
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины.

Требования к `elasticsearch.yml`:

- данные `path` должны сохраняться в `/var/lib`,
- имя ноды должно быть `netology_test`.

В ответе приведите:

- текст Dockerfile-манифеста,
- ссылку на образ в репозитории dockerhub,
- ответ `Elasticsearch` на запрос пути `/` в json-виде.

Подсказки:

- возможно, вам понадобится установка пакета perl-Digest-SHA для корректной работы пакета shasum,
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml,
- при некоторых проблемах вам поможет Docker-директива ulimit,
- Elasticsearch в логах обычно описывает проблему и пути её решения.

Далее мы будем работать с этим экземпляром Elasticsearch.  


### Решение:  

- Я очень долго пилил эту задачу. Файл elasticsearch.yml, который я подкинул в контейнер вместо стандартного - прилагаю.

- Текст dockerfile-манифеста:

```
FROM centos:7

MAINTAINER Aleksey Lebedev FOPS-10

RUN groupadd -g 1000 elasticsearch && useradd elasticsearch -u 1000 -g 1000

RUN yum install -y java-1.8.0-openjdk

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
RUN echo -e "[elasticsearch-7.x]\nname=Elasticsearch repository for 7.x packages\nbaseurl=https://artifacts.elastic.co/packages/7.x/yum\ngpgcheck=1\ngpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\nenabled=1\nautorefresh=1\nty$
RUN yum install -y elasticsearch

COPY elasticsearch.yml /etc/elasticsearch/

USER elasticsearch

EXPOSE 9200


CMD ["/usr/share/elasticsearch/bin/elasticsearch"]
```

- Ссылка на запушенный image:

**https://hub.docker.com/repository/docker/luckynucky/elastic-fixed/general**   - стабильный образ - 1.3

- Ответ от курла:

```
root@elastic:/home/vagrant/elastic_docker_project# curl http://localhost:9200/
{
  "name" : "netology_test",
  "cluster_name" : "lebedev_cluster",
  "cluster_uuid" : "_na_",
  "version" : {
    "number" : "7.17.14",
    "build_flavor" : "default",
    "build_type" : "rpm",
    "build_hash" : "774e3bfa4d52e2834e4d9d8d669d77e4e5c1017f",
    "build_date" : "2023-10-05T22:17:33.780167078Z",
    "build_snapshot" : false,
    "lucene_version" : "8.11.1",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

- Вывод статуса кластера:

```
root@elastic:/home/vagrant/elastic_docker_project# curl -XGET 'localhost:9200/_cluster/health?pretty'
{
  "cluster_name" : "lebedev_cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 3,
  "active_shards" : 3,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
```

---



## Задача 2

В этом задании вы научитесь:

- создавать и удалять индексы,
- изучать состояние кластера,
- обосновывать причину деградации доступности данных.

Ознакомьтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `Elasticsearch` 3 индекса в соответствии с таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API, и **приведите в ответе** на задание.

Получите состояние кластера `Elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находятся в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера Elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.  

### Решение:  

- Добавим три индекса, руководствуясь таблицей выше и проверим статус:

```
root@elastic:/home/vagrant/elastic_docker_project# curl 'localhost:9200/_cat/indices?v&pretty'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases kIWNmifFRtiOJpcuF0FIiw   1   0         41            0     38.2mb         38.2mb
yellow open   my-index-000003  GBD7q_GgS7O3iF27f9YrXA   4   2          0            0       908b           908b
yellow open   my-index-000002  FxbUwU3NS3mH7kDfZ4wyuA   2   1          0            0       454b           454b
green  open   my-index-000001  mx7k4tlzQBCxM50SMPLYdg   1   0          0            0       227b           227b
```

- Еще раз проверим состояние кластера:

```
root@elastic:/home/vagrant/elastic_docker_project# curl -XGET 'localhost:9200/_cluster/health?pretty'
{
  "cluster_name" : "lebedev_cluster",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 10,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 50.0
```

- Часть индексов и состояние кластера "пожелтели" ввиду того, что у нас сингл-нода, что противоречит нашей логике при создании такого количества реплик и шардов. Зеленый - только первый индекс и это правильно.

- Удалим все созданные нами индексы:

```
root@elastic:/home/vagrant/elastic_docker_project# curl -XDELETE "localhost:9200/my-index-000001?pretty"
{
  "acknowledged" : true
}
root@elastic:/home/vagrant/elastic_docker_project# curl 'localhost:9200/_cat/indices?v&pretty'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases kIWNmifFRtiOJpcuF0FIiw   1   0         41            0     38.2mb         38.2mb
yellow open   my-index-000003  GBD7q_GgS7O3iF27f9YrXA   4   2          0            0       908b           908b
yellow open   my-index-000002  FxbUwU3NS3mH7kDfZ4wyuA   2   1          0            0       454b           454b
root@elastic:/home/vagrant/elastic_docker_project# curl -XDELETE "localhost:9200/my-index-000002?pretty"
{
  "acknowledged" : true
}
root@elastic:/home/vagrant/elastic_docker_project# curl -XDELETE "localhost:9200/my-index-000003?pretty"
{
  "acknowledged" : true
}
root@elastic:/home/vagrant/elastic_docker_project# curl 'localhost:9200/_cat/indices?v&pretty'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases kIWNmifFRtiOJpcuF0FIiw   1   0         41            0     38.2mb         38.2mb
root@elastic:/home/vagrant/elastic_docker_project#
```

---

## Задача 3

В этом задании вы научитесь:

- создавать бэкапы данных,
- восстанавливать индексы из бэкапов.

Создайте директорию `{путь до корневой директории с Elasticsearch в образе}/snapshots`.

Используя API, [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
эту директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `Elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `Elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:

- возможно, вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `Elasticsearch`.

### Решение:  

- Выполнение данного задания, также, заняло у меня много времени. Для начала, пришлось подкорректировать доккерфайл, elasticsearch.yaml и пересобрать образ.

- Каталог для backup'а был создан по пути: /etc/elasticsearch/snapshots

- Вводим настройки:

```
root@elastic:/home/vagrant# curl -X PUT "localhost:9200/_snapshot/netology_backup?verify=false&pretty" -H 'Content-Type: application/json' -d'
> {
>   "type": "fs",
>   "settings": {
>     "location": "/etc/elasticsearch/snapshots"
>   }
> }
> '
{
  "acknowledged" : true
}
```

- Верифицируем:

```
root@elastic:/home/vagrant# curl -X POST "localhost:9200/_snapshot/netology_backup/_verify?pretty"
{
  "nodes" : {
    "1eLukXEVRuS28ypFIj6zYw" : {
      "name" : "netology_test"
    }
  }
}
```

- Делаем полный снапшот:

```
root@elastic:/home/vagrant# curl -X PUT "localhost:9200/_snapshot/netology_backup/my_snapshot?wait_for_completion=true&pretty"
{
  "snapshot" : {
    "snapshot" : "my_snapshot",
    "uuid" : "IbhVZ5KjRMGc5bb2jyOc-A",
    "repository" : "netology_backup",
    "version_id" : 7171499,
    "version" : "7.17.14",
    "indices" : [
      ".ds-.logs-deprecation.elasticsearch-default-2023.11.09-000001",
      "test",
      ".ds-ilm-history-5-2023.11.09-000001",
      ".geoip_databases"
    ],
    "data_streams" : [
      "ilm-history-5",
      ".logs-deprecation.elasticsearch-default"
    ],
    "include_global_state" : true,
    "state" : "SUCCESS",
    "start_time" : "2023-11-09T14:11:32.393Z",
    "start_time_in_millis" : 1699539092393,
    "end_time" : "2023-11-09T14:11:32.593Z",
    "end_time_in_millis" : 1699539092593,
    "duration_in_millis" : 200,
    "failures" : [ ],
    "shards" : {
      "total" : 4,
      "failed" : 0,
      "successful" : 4
    },
    "feature_states" : [
      {
        "feature_name" : "geoip",
        "indices" : [
          ".geoip_databases"
        ]
      }
    ]
  }
}
```

- Можем даже сходить в доккер и посмотреть в папку со снапшотами:

```
root@elastic:/home/vagrant# docker exec -it -u root 09841c63a7f7 /bin/sh
sh-4.2# cd /etc/elasticsearch/snapshots/
sh-4.2# ls -lai
total 96
3147911 drwxrwsr-x 1 root          elasticsearch  4096 Nov  9 14:11 .
3147914 drwxr-s--- 1 root          elasticsearch  4096 Nov  9 12:57 ..
3148216 -rw-r--r-- 1 elasticsearch elasticsearch  1972 Nov  9 14:11 index-1
3148217 -rw-r--r-- 1 elasticsearch elasticsearch     8 Nov  9 14:11 index.latest
3148139 drwxr-sr-x 6 elasticsearch elasticsearch  4096 Nov  9 14:08 indices
3148210 -rw-r--r-- 1 elasticsearch elasticsearch 29303 Nov  9 14:11 meta-IbhVZ5KjRMGc5bb2jyOc-A.dat
3148190 -rw-r--r-- 1 elasticsearch elasticsearch 29303 Nov  9 14:08 meta-VJ5Cj3h4RnGZZsLlnDFBBQ.dat
3148218 -rw-r--r-- 1 elasticsearch elasticsearch   710 Nov  9 14:11 snap-IbhVZ5KjRMGc5bb2jyOc-A.dat
3148208 -rw-r--r-- 1 elasticsearch elasticsearch   721 Nov  9 14:08 snap-VJ5Cj3h4RnGZZsLlnDFBBQ.dat
```

- По итогу, я сделал несколько снапшотов разными способами:

```
root@elastic:/home/vagrant# curl -X GET "localhost:9200/_cat/snapshots/netology_backup?v=true&s=id&pretty"
id                     repository       status start_epoch start_time end_epoch  end_time duration indices successful_shards failed_shards total_shards
my_snapshot            netology_backup SUCCESS 1699539092  14:11:32   1699539092 14:11:32    200ms       4                 4             0            4
my_snapshot_2023.11.09 netology_backup SUCCESS 1699538910  14:08:30   1699538912 14:08:32     1.4s       4                 4             0            4
root@elastic:/home/vagrant#
```

- Ну и посмотрим индексы на данный момент:

```
root@elastic:/home/vagrant# curl 'localhost:9200/_cat/indices?v&pretty'
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases jWDiQ8eqQRiVWvU33wfwzQ   1   0         41            0     38.2mb         38.2mb
green  open   test             cuZ1JqaxSxOkMCuTBWDR6g   1   0          0            0       227b           227b
```

- 




---

### Как cдавать задание

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
