import pika 


rmq_server = "16.171.196.128"
credentials = pika.PlainCredentials('guest', 'guest')
parameters = pika.ConnectionParameters(rmq_server, 5672, '/', credentials)

connection = pika.BlockingConnection(parameters)
channel = connection.channel()

channel.queue_declare(queue='admin')

def callback(ch, method, properties, body):
    print('ADMIN:')
    print(body)

channel.basic_consume(queue='admin', on_message_callback=callback)


print('Started consuming')

channel.start_consuming()
