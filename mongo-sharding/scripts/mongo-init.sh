#!/bin/bash

# 1. Инициализация сервера конфигурации
docker compose exec -T configsvr mongosh <<EOF
rs.initiate({
  _id: 'configReplSet',
  configsvr: true,
  members: [{ _id: 0, host: 'configsvr:27017' }]
})
EOF

# Ожидание инициализации конфиг-сервера
sleep 5

# 2. Инициализация первого шарда
docker compose exec -T shard1 mongosh <<EOF
rs.initiate({
  _id: 'shard1',
  members: [{ _id: 0, host: 'shard1:27017' }]
})
EOF

# 3. Инициализация второго шарда
docker compose exec -T shard2 mongosh <<EOF
rs.initiate({
  _id: 'shard2',
  members: [{ _id: 0, host: 'shard2:27017' }]
})
EOF

# Ожидание инициализации реплика-сетов шардов
sleep 5

# 4. Настройка роутера (добавление шардов и включение шардирования)
docker compose exec -T mongos_router mongosh <<EOF
sh.addShard('shard1/shard1:27017')
sh.addShard('shard2/shard2:27017')
sh.enableSharding('somedb')
use somedb
sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' })
EOF

# 5. Наполнение тестовыми данными
docker compose exec -T mongos_router mongosh <<EOF
use somedb
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: 'ly' + i})
}
EOF

# 6. Проверка распределения данных
docker compose exec -T mongos_router mongosh <<EOF
use somedb
db.helloDoc.getShardDistribution()
EOF