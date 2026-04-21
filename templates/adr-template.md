# Architecture Decision Record (ADR)

**ADR ID**: ADR-[###]  
**Title**: [Short title describing decision]  
**Status**: Proposed | **Accepted** | Deprecated | Superseded  
**Date**: [YYYY-MM-DD]  
**Author**: [Name]  

> **SDLC alignment:** Decisions must be traceable to **system design**, **Tech Story**, or **Sprint/Master** scope. Cross-check [`AUTHORING_STANDARDS.md`](AUTHORING_STANDARDS.md) (traceability, no orphan decisions).

---

## Context
Explain the issue or problem that motivated this decision. Include:
- What technical question needs answering?
- What constraints exist (time, budget, skill)?
- What triggered re-evaluation?

Example: "We need to choose a messaging queue for event distribution. Current solution (single database polling) creates bottlenecks at 1K events/sec."

---

## Decision Drivers
Priority-ranked factors influencing decision:
1. **Throughput**: Must handle 10K events/sec
2. **Latency**: Event delivery <100ms (p95)
3. **Operational Simplicity**: Minimal deployment/maintenance
4. **Cost**: <$500/month infrastructure
5. **Team Expertise**: Java/Go (not Rust/Erlang)

---

## Options Considered

### Option A: Kafka
**Pros**:
- Highest throughput (1M events/sec+)
- Persistent event log (replay capability)
- Strong ecosystem (Confluent, Debezium)

**Cons**:
- Operational overhead (cluster management)
- Overkill for current volume (10K events/sec)
- Team has limited Kafka expertise

**Cost**: ~$800/month (managed Confluent Cloud)

---

### Option B: AWS SQS + SNS
**Pros**:
- Fully managed (no ops)
- Low cost (~$100/month)
- AWS native (easy integration)

**Cons**:
- Delivery guarantees weaker (eventual consistency)
- Message size limited (256KB)
- Less flexible for complex routing

**Cost**: ~$100/month

---

### Option C: RabbitMQ
**Pros**:
- Self-hosted (full control)
- Flexible routing (topic exchanges)
- Good Java client library

**Cons**:
- Requires cluster setup/monitoring
- Less mature persistence than Kafka
- Team expertise moderate

**Cost**: ~$200/month (infrastructure)

---

## Decision
**Selected: Option B (AWS SQS + SNS)**

Rationale:
- Current volume (10K events/sec) well below Kafka's need
- Managed service reduces operational burden (3-person team)
- Cost efficiency ($100/month vs $800) aligns with budget
- AWS familiarity reduces learning curve
- Upgrade path clear (migrate to Kafka if volume exceeds 50K events/sec)

---

## Consequences

### Positive
- Faster time-to-market (no cluster setup)
- Lower operational complexity
- Team can focus on business logic, not infrastructure

### Negative
- Message ordering not guaranteed across consumers
- Message retention limited (14 days max)
- Less visibility into event processing
- Potential lock-in to AWS services

### Risks
- If volume grows 10x unexpectedly, SQS may become bottleneck
- Eventual consistency may cause downstream issues if not handled properly

---

## Mitigation
1. Implement monitoring on queue depth (alert if >50K messages)
2. Design event handlers to be idempotent (handle duplicates)
3. Document upgrade path to Kafka (ADR-025 future)
4. Load test quarterly to validate assumptions

---

## References
- [AWS SQS Best Practices](https://docs.aws.amazon.com/sqs/)
- [Kafka vs SQS Comparison](https://example.com/comparison)
- Related ADR: ADR-024 (Database choice)
- Supersedes: ADR-015 (polling approach)

---

## Approval History
- **Proposed**: [date] by [name]
- **Accepted**: [date] by Architecture Review Board
- **Superseded By**: ADR-025 (if applicable)

---
**Status**: Ready for review ✓
