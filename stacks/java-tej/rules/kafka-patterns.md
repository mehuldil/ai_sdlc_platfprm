# Kafka Patterns (Java TEJ)

## Producer Pattern
- **Singleton pattern**: One KafkaProducer per service
- Configuration:
  ```properties
  bootstrap.servers=kafka:9092
  acks=all
  retries=3
  compression.type=snappy
  ```
- **Thread-safe**: Share single producer across threads

## Consumer Pattern
- **Manual commit**: `enable.auto.commit=false`
- **Offset management**: Commit after processing completes
- Pattern:
  ```java
  ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(1));
  for (ConsumerRecord<String, String> record : records) {
    processMessage(record);
    consumer.commitSync();
  }
  ```

## Message Serialization
- Format: JSON (Gson serialized)
- Encoding: UTF-8
- Schema versioning: Include `version` field in message payload

## Dead Letter Queue (DLQ)
- Topic: `{original-topic}-dlq`
- Routing: Send failed messages to DLQ after max retries
- Pattern:
  ```java
  try {
    processMessage(record);
  } catch (ProcessingException e) {
    sendToDLQ(record, e);
  }
  ```

## Monitoring
- Log message count per poll
- Track DLQ depth (alert if >100 messages)
- Monitor consumer lag via JMX

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
