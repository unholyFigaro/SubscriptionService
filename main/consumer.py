import pika, json
from main import Product, db

rmq_server = "16.171.196.128"
credentials = pika.PlainCredentials('guest', 'guest')
parameters = pika.ConnectionParameters(rmq_server, 5672, '/', credentials)

connection = pika.BlockingConnection(parameters)
channel = connection.channel()

channel.queue_declare(queue='main')

def callback(ch, method, properties, body):
    print('main:')
    data=json.loads(body)
    print(data)

    if properties.content_type=='product_created':
        product = Product(id=data['id'], title=data['title'], image=data['image'])
        db.session.add(product)
        db.session.commit()
        print("Product craeted")

    elif properties.content_type=='product_updated':
        product = Product.query.get(data['id'])
        product.title = data['title']
        product.image = data['image']
        db.session.commit()
        print("Product updated")

    elif properties.content_type=='product_deleted':
        product= Product.query.get(data)
        db.session.delete(product)
        db.session.commit()
        print("Product deleted")

channel.basic_consume(queue='main', on_message_callback=callback, auto_ack=True)


print('Started consuming')

channel.start_consuming()
