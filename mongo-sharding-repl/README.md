# Задание 3. Шардироание + Репликация

# 1. Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```



# 2. Шаги по настроке Шардирования и Репликаций

## Подключение к серверу конфигурации и инициализация:
```shell
docker exec -it configsvr mongosh --eval "rs.initiate({_id: 'configReplSet', configsvr: true, members: [{_id: 0, host: 'configsvr:27017'}]})"
```

## Инициализация шардов:
```shell
# Первый шард
docker compose exec -T shard1-1 mongosh --eval "rs.initiate({
  _id: 'shard1RS',
  members: [
    { _id: 0, host: 'shard1-1:27017' },
    { _id: 1, host: 'shard1-2:27017' },
    { _id: 2, host: 'shard1-3:27017' }
  ]
})"

# Второй шард
docker compose exec -T shard2-1 mongosh --eval "rs.initiate({
  _id: 'shard2RS',
  members: [
    { _id: 0, host: 'shard2-1:27017' },
    { _id: 1, host: 'shard2-2:27017' },
    { _id: 2, host: 'shard2-3:27017' }
  ]
})"
```

## Подключение шардов к роутеру
```shell
docker compose exec -T mongos_router mongosh --eval "
  sh.addShard('shard1RS/shard1-1:27017,shard1-2:27017,shard1-3:27017');
  sh.addShard('shard2RS/shard2-1:27017,shard2-2:27017,shard2-3:27017');
"
```

## Настройка шардирования
```shell
docker exec -it mongos_router mongosh --eval "sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' } )"
```


## Наполнение  тестовыми данными
```shell
docker exec -it mongos_router mongosh somedb --eval "for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:'ly'+i})"
```
## Просмотр количества записей на шардах
```shell
docker exec -it mongos_router mongosh somedb --eval "db.helloDoc.getShardDistribution()"
```

# 3. Общий скрипт по настройке к заданию Шардироание + Репликация
Все скриты по инициализации помещены в файл
```shell
./scripts/mongo-init.sh
```

# 4. Результаты задание
После успешного выплолнения скрипта должна быть выведена информация о распределении записей по шардам:
![Результат скрипта](/docs/images/task3_result.PNG)

Результат открытия приложения
![Результат 8080](/docs/images/task3_result_8080.PNG)