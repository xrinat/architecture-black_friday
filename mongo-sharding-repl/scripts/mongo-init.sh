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

# 2. Инициализация Реплика-сета для Шарда 1 (3 узла)
docker compose exec -T shard1-1 mongosh <<EOF
rs.initiate({
  _id: 'shard1RS',
  members: [
    { _id: 0, host: 'shard1-1:27017' },
    { _id: 1, host: 'shard1-2:27017' },
    { _id: 2, host: 'shard1-3:27017' }
  ]
})
EOF

# 3. Инициализация Реплика-сета для Шарда 2 (3 узла)
docker compose exec -T shard2-1 mongosh <<EOF
rs.initiate({
  _id: 'shard2RS',
  members: [
    { _id: 0, host: 'shard2-1:27017' },
    { _id: 1, host: 'shard2-2:27017' },
    { _id: 2, host: 'shard2-3:27017' }
  ]
})
EOF

# Ожидание завершения выборов Primary в шардах
sleep 5

# 4. Настройка роутера (добавление Шард-реплика-сетов)
docker compose exec -T mongos_router mongosh <<EOF
sh.addShard('shard1RS/shard1-1:27017,shard1-2:27017,shard1-3:27017')
sh.addShard('shard2RS/shard2-1:27017,shard2-2:27017,shard2-3:27017')
sh.enableSharding('somedb')
use somedb
sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' })
EOF

# 5. Наполнение тестовыми данными через роутер
docker compose exec -T mongos_router mongosh <<EOF
use somedb
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: 'ly' + i})
}
EOF

# 6. Проверка распределения данных по шардам
docker compose exec -T mongos_router mongosh <<EOF
use somedb
db.helloDoc.getShardDistribution()
EOF