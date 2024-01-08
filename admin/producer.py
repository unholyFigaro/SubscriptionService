# import pika 

# params = pika.URLParameters('amqps://guest:guest@16.171.196.128:15672/')
# connection=pika.BlockingConnection(params)

# channel =connection.channel()

import pika

rmq_server = "16.171.196.128"
credentials = pika.PlainCredentials('guest', 'guest')
parameters = pika.ConnectionParameters(rmq_server, 5672, '/', credentials)

connection = pika.BlockingConnection(parameters)
channel = connection.channel()


def publish(method, body):
    channel.basic_publish(exchange='', routing_key='admin', body='hello')