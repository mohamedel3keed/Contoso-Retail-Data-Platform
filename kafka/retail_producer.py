import json
import time
import uuid
import random
from datetime import datetime, timezone

from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers=["localhost:9092", 'localhost:9093', 'localhost:9094'],
    value_serializer=lambda value: json.dumps(value).encode("utf-8"),
    key_serializer=lambda key: key.encode("utf-8"),
    enable_idempotence=True,
    acks="all",
)

topic = "retail-sales"

try:
    print("Producing retail sales events... Press Ctrl+C to stop.")

    KEYS = json.load(open("../data-lake/reference/event_keys.json"))
    RATE = 10                                    # أحداث في الثانية

    def make_event():
        pid = random.choice(list(KEYS["products"]))
        qty = random.randint(1, 5)
        return {
            "EventID": str(uuid.uuid4()),
            "EventType": "SaleCompleted",
            "EventTime": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
            "CustomerID": random.choice(KEYS["customers"]),
            "ProductID": int(pid),
            "StoreID": random.choice(KEYS["stores"]),
            "Quantity": qty,
            "Amount": round(qty * KEYS["products"][pid], 2),
            "Source": "event-generator",
        }

    sent = 0
    def on_ok(md):
        global sent
        sent += 1
        if sent % 100 == 0:
            print("sent=%d  last: partition=%d offset=%d" % (sent, md.partition, md.offset))

    while True:
        ev = make_event()
        producer.send(topic, key=str(ev["StoreID"]), value=ev).add_callback(on_ok).add_errback(print)
        time.sleep(1.0 / RATE)

except KeyboardInterrupt:
    print("\nProducer stopped.")

finally:
    producer.flush()
    producer.close()
