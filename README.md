# TestDurableQueue

Example of cleanly auto-reconnect durable queue to RabbitMQ, especially in times of cluster membership changes.

[Connection should be shared, channel should be bound to queue(s).](https://www.rabbitmq.com/tutorials/amqp-concepts.html#amqp-channels)

Tested with local cluster w/ docker:

```
docker network create rabbit

docker run -d --network rabbit --name rabbit1  -p "5672:5672" -p "15672:15672" -e RABBITMQ_NODENAME="rabbit@rabbit1" -e RABBITMQ_ERLANG_COOKIE="adfsder" rabbitmq:alpine

docker exec rabbit1 rabbitmq-plugins enable rabbitmq_management
docker exec rabbit1 rabbitmqctl stop_app
docker exec rabbit1 rabbitmqctl reset
docker exec rabbit1 rabbitmqctl start_app
docker exec rabbit1 rabbitmqctl add_vhost xyz
docker exec rabbit1 rabbitmqctl set_permissions -p xyz guest ".*" ".*" ".*"

docker run -d --network rabbit --name rabbit2 -e RABBITMQ_NODENAME="rabbit@rabbit2" -e RABBITMQ_ERLANG_COOKIE="adfsder" rabbitmq:alpine

docker exec rabbit2 rabbitmq-plugins enable rabbitmq_management
docker exec rabbit2 rabbitmqctl stop_app
docker exec rabbit2 rabbitmqctl reset
docker exec rabbit2 rabbitmqctl start_app
docker exec rabbit2 rabbitmqctl stop_app
docker exec rabbit2 rabbitmqctl join_cluster rabbit@rabbit1
docker exec rabbit2 rabbitmqctl start_app

# create queue on rabbit2 (through UI)

# `iex -S mix` or start your test app

# check things running

docker rm -f rabbit2

# observer "home node" error

docker exec rabbit1 rabbitmqctl forget_cluster_node rabbit@rabbit2

# check rabbitmq management ui overview

# queue is gone

# if still retrying, now can recreate queue...


# with (not clean) try-catch retry loop - if restart app -, duplicated connection, 1 channel, new queue has no consumer
# connection (& channel) is on rabbit1


# when queue is gone, channel is still "connected to that queue", so need to clean up channel


# channel should be bound to a (set of) queue - cleanup together


# final result: clean connection, 1 channel when queue is created, queue can be created as soon as dead node is removed from cluster


# with HA queues (completely transparent to application?)


# admin UI on rabbit1, port on rabbit2

docker run -d --network rabbit --name rabbit1 -p "15672:15672" -e RABBITMQ_NODENAME="rabbit@rabbit1" -e RABBITMQ_ERLANG_COOKIE="adfsder" rabbitmq:alpine

docker exec rabbit1 rabbitmq-plugins enable rabbitmq_management
docker exec rabbit1 rabbitmqctl stop_app
docker exec rabbit1 rabbitmqctl reset
docker exec rabbit1 rabbitmqctl start_app
docker exec rabbit1 rabbitmqctl add_vhost xyz
docker exec rabbit1 rabbitmqctl set_permissions -p xyz guest ".*" ".*" ".*"

docker run -d --network rabbit --name rabbit2 -p "5672:5672" -e RABBITMQ_NODENAME="rabbit@rabbit2" -e RABBITMQ_ERLANG_COOKIE="adfsder" rabbitmq:alpine

docker exec rabbit2 rabbitmq-plugins enable rabbitmq_management
docker exec rabbit2 rabbitmqctl stop_app
docker exec rabbit2 rabbitmqctl reset
docker exec rabbit2 rabbitmqctl start_app
docker exec rabbit2 rabbitmqctl stop_app
docker exec rabbit2 rabbitmqctl join_cluster rabbit@rabbit1
docker exec rabbit2 rabbitmqctl start_app

# need proxy (nginx/HAProxy) for 5672 port "transfer" after removing rabbit2


# to add another node into the cluster

docker run -d --network rabbit --name rabbit3 -e RABBITMQ_NODENAME="rabbit@rabbit3" -e RABBITMQ_ERLANG_COOKIE="adfsder" rabbitmq:alpine

docker exec rabbit3 rabbitmq-plugins enable rabbitmq_management
docker exec rabbit3 rabbitmqctl stop_app
docker exec rabbit3 rabbitmqctl reset
docker exec rabbit3 rabbitmqctl start_app
docker exec rabbit3 rabbitmqctl stop_app
docker exec rabbit3 rabbitmqctl join_cluster rabbit@rabbit1
docker exec rabbit3 rabbitmqctl start_app






# cleanup

docker rm -f rabbit1 rabbit2 rabbit3

docker network rm rabbit
```
