# TestDurableQueue

Example of cleanly auto-reconnect durable queue to RabbitMQ, especially in times of cluster membership changes.

Checkout [my blog](https://blog.aquarhead.me/2018/07/stable_rabbitmq)!

## Features

- Reuse connection: no reconnect (recreation of `Connection`) unless the connected node (on AMQP side) fails
- Exactly one channel, and resilent to queue failure (queue down due to RabbitMQ cluster changes)
- Useful logging (with `lager` because it's bundled with `amqp_client`)
- Example of passing in options through `Supervisor` layers
