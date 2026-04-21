# NFR Targets (Non-Functional Requirements)

## Organization Defaults
These are the baseline NFR targets for all systems unless explicitly overridden in PRD.

## Latency Targets
- **P50 (Median)**: Report for baseline
- **P95 (95th percentile)**: <200ms
- **P99 (99th percentile)**: <500ms
- **Measurement**: End-to-end, including network round-trip

## Availability & Error Rates
- **Availability**: 99.9% (8.76 hours downtime/year)
- **Error rate**: <0.1% (1 error per 1000 requests)
- **SLA window**: Measured per 24-hour rolling window

## Throughput
- **Minimum**: >500 RPS (requests per second)
- **Burst capacity**: 2x sustained rate
- **Connection pooling**: Required for database access

## Mobile App Performance
- **App startup**: <2 seconds (cold start)
- **FPS (frames per second)**: >=60 FPS
- **Memory**: <150MB peak usage
- **CPU**: <70% utilization under normal load

## Reporting Requirements
Stories and epics **must always report** all three percentiles:
- ✓ P50 (baseline/median)
- ✓ P95 (tail latency)
- ✓ P99 (worst-case)

## Override Policy
- **Stricter targets**: Stories may require tighter NFRs (e.g., P95 <100ms)
- **Relaxed targets**: Requires CTO approval to exceed defaults
- **Documentation**: All overrides must be documented in PRD
- **Rationale**: Include business case or technical justification

---
**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
