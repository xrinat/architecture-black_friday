# Задание 2. Шардирование

## Как запустить

Запускаем mongodb и приложение и папки "mongo-sharding"

```shell
docker compose up -d
```

## Заполняем mongodb данными
Все скриты по инициализации помещены в файл
```shell
./scripts/mongo-init.sh
```
После успешного выплолнения скрипта должна быть выведена информация о распределении записей по шардам:
![Результат скрипта](/docs/images/task2_result.PNG)
Результат открытия приложения
![Результат 8080](/docs/images/task2_result_8080.PNG)







# Примечания от создателя
Не стал раскидывать по разным портам.<br><br>
Далее идёт отладочная информация по шагам, которые были сделаны.<br> 
Не для проверки ревьюером.<br> 
Подключитесь к серверу конфигурации и сделайте инициализацию:
```shell
docker exec -it configsvr mongosh --eval "rs.initiate({_id: 'configReplSet', configsvr: true, members: [{_id: 0, host: 'configsvr:27017'}]})"
```

Инициализируйте шарды:
```shell
# Первый шард
docker exec -it shard1 mongosh --eval "rs.initiate({_id: 'shard1', members: [{_id: 0, host: 'shard1:27017'}]})"

# Второй шард
docker exec -it shard2 mongosh --eval "rs.initiate({_id: 'shard2', members: [{_id: 0, host: 'shard2:27017'}]})"
```

Инцициализируйте роутер и наполните его тестовыми данными:
```shell
docker exec -it mongos_router mongosh --eval "sh.addShard('shard1/shard1:27017')"
docker exec -it mongos_router mongosh --eval "sh.addShard('shard2/shard2:27017')"

docker exec -it mongos_router mongosh --eval "sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' } )"

docker exec -it mongos_router mongosh somedb --eval "for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:'ly'+i})"
```
Просмотрите количества записей на шардах
```shell
docker exec -it mongos_router mongosh somedb --eval "db.helloDoc.getShardDistribution()"
```



