"""
Kafka consumer -> Data Lake (Bronze streaming files)

- joins the consumer group GROUP, so Kafka remembers the position (offset) of every partition
- buffers events and writes them as JSON-lines files:  <LAKE_DIR>/<topic>/events_p<partition>_o<first>-<last>.jsonl
  every row = the original event + the Kafka metadata (_topic, _partition, _offset, _kafka_timestamp, _key, _ingested_at)
- commits the offsets ONLY AFTER the file is safely written  (at-least-once: a crash between the two steps
  can replay a few events after the restart -> they are removed later by EventID)
- a message that is not valid JSON is not lost: it is written with _malformed = true and the raw text

Stop it with Ctrl+C, produce more events, start it again: it continues from the last committed offset.
Run a second copy in another terminal (same GROUP): Kafka splits the 3 partitions between the two copies.

    pip install kafka-python
    python consumer.py
"""
import json
import os
import time
from datetime import datetime, timezone

from kafka import KafkaConsumer

BOOTSTRAP = ["localhost:9092", "localhost:9093", "localhost:9094"]      # same as the producer (clients on your PC)
TOPIC = "retail-sales"
GROUP = "retail-lake-writer"
LAKE_DIR = os.environ.get(
    "LAKE_STREAM_DIR",
    r"D:\Data Engineering\Course Data\Data_Pill - DE - Final_Project\Answer\data-lake\bronze_stream",
)
OUT_DIR = os.path.join(LAKE_DIR, TOPIC)
MAX_BATCH = 200          # write after this many events ...
MAX_WAIT = 10            # ... or after this many seconds, whichever comes first


def safe_json(raw):
    try:
        value = json.loads(raw.decode("utf-8"))

        if not isinstance(value, dict):
            return {
                "_malformed": True,
                "_raw": raw.decode("utf-8", "replace")
            }

        return value

    except Exception:
        return {
            "_malformed": True,
            "_raw": raw.decode("utf-8", "replace")
        }


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def flush(buffer, out_dir):
    """buffer = {partition: [records]}  ->  one JSON-lines file per partition, written atomically."""
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for partition, records in sorted(buffer.items()):
        name = "events_p%d_o%d-%d.jsonl" % (partition, records[0].offset, records[-1].offset)
        tmp = os.path.join(out_dir, "." + name + ".tmp")      # starts with "." -> Spark's file source ignores it until the rename
        with open(tmp, "w", encoding="utf-8") as f:
            for r in records:
                row = dict(r.value)
                row.update({"_topic": r.topic, "_partition": r.partition, "_offset": r.offset,
                            "_kafka_timestamp": r.timestamp, "_key": r.key, "_ingested_at": utc_now()})
                f.write(json.dumps(row) + "\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, os.path.join(out_dir, name))        # the visible file appears only when it is complete
        print("  wrote %-36s events=%d" % (name, len(records)))
        total += len(records)
    return total


def show_offsets(consumer):
    parts = sorted(consumer.assignment(), key=lambda t: t.partition)
    ends = consumer.end_offsets(parts)
    for tp in parts:
        committed = consumer.committed(tp) or 0
        print("    partition %d  committed=%-8d log-end=%-8d lag=%d" % (tp.partition, committed, ends[tp], ends[tp] - committed))


def main():
    consumer = KafkaConsumer(
        TOPIC,
        bootstrap_servers=BOOTSTRAP,
        group_id=GROUP,
        enable_auto_commit=False,              # we commit ourselves, after the write
        auto_offset_reset="earliest",          # first run of a new group: start from the beginning
        max_poll_records=500,
        key_deserializer=lambda k: k.decode("utf-8") if k else None,
        value_deserializer=safe_json,
    )
    print("consumer started | topic=%s group=%s | writing to %s" % (TOPIC, GROUP, OUT_DIR))
    print("Ctrl+C to stop\n")

    buffer, count, last_flush = {}, 0, time.time()
    try:
        while True:
            batch = consumer.poll(timeout_ms=1000)
            if consumer.assignment() and not getattr(consumer, "_announced", False):
                consumer._announced = True
                print("assigned partitions:", sorted(tp.partition for tp in consumer.assignment()))
                show_offsets(consumer)
            for tp, records in batch.items():
                buffer.setdefault(tp.partition, []).extend(records)
                count += len(records)
            if not count:
                last_flush = time.time()
            elif count >= MAX_BATCH or time.time() - last_flush >= MAX_WAIT:
                flush(buffer, OUT_DIR)
                consumer.commit()                  # only now Kafka "forgets" these events for this group
                show_offsets(consumer)
                buffer, count, last_flush = {}, 0, time.time()
    except KeyboardInterrupt:
        print("\nstopping ...")
    finally:
        if count:
            flush(buffer, OUT_DIR)
            consumer.commit()
            show_offsets(consumer)
        consumer.close()
        print("consumer closed")


if __name__ == "__main__":
    main()