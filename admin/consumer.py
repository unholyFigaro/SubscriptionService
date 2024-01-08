import pika, json, os, django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "admin.settings")
django.setup()

from products.models import Product


rmq_server = "16.171.196.128"
credentials = pika.PlainCredentials('guest', 'guest')
parameters = pika.ConnectionParameters(rmq_server, 5672, '/', credentials)

connection = pika.BlockingConnection(parameters)
channel = connection.channel()

channel.queue_declare(queue='admin')

def callback(ch, method, properties, body):
    print('ADMIN:')
    id = json.loads(body)
    print(id)
    product = Product.objects.get(id=id)
    product.subs = product.subs + 1
    product.save()
    print('Product subs increased!')
channel.basic_consume(queue='admin', on_message_callback=callback, auto_ack=True)


print('Started consuming')

channel.start_consuming()

channel.close()
