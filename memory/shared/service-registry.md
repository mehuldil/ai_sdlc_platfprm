# Service Registry

**Last Updated**: [date]  
**Maintained By**: Architecture Team  

---

## Active Services

### auth-service
| Field | Value |
|-------|-------|
| **Owner** | Backend Team (John Doe) |
| **Repository** | github.com/example-org/auth-service |
| **Status** | EXISTING (Production) |
| **Language** | Java 17 |
| **Last ADR** | ADR-005 (OAuth2 Integration) |
| **API Version** | v2.0 (OpenAPI 3.1) |
| **Dependencies** | PostgreSQL, Redis |
| **Deployment** | Kubernetes (AWS EKS) |
| **SLA** | 99.95% uptime |
| **Contact** | #backend-team Slack |

---

### profile-service
| Field | Value |
|-------|-------|
| **Owner** | Backend Team (Jane Smith) |
| **Repository** | github.com/example-org/profile-service |
| **Status** | EXISTING (Production) |
| **Language** | Java 17 |
| **Last ADR** | ADR-008 (Profile Caching Strategy) |
| **API Version** | v1.5 (OpenAPI 3.1) |
| **Dependencies** | PostgreSQL, Redis, auth-service |
| **Deployment** | Kubernetes (AWS EKS) |
| **SLA** | 99.9% uptime |
| **Contact** | #backend-team Slack |

---

### notification-service
| Field | Value |
|-------|-------|
| **Owner** | Backend Team (Bob Johnson) |
| **Repository** | github.com/example-org/notification-service |
| **Status** | EXISTING (Production) |
| **Language** | Java 17 |
| **Last ADR** | ADR-012 (Event-Driven Notifications) |
| **API Version** | v1.0 (OpenAPI 3.1) |
| **Dependencies** | Kafka, SendGrid, Twilio |
| **Deployment** | Kubernetes (AWS EKS) |
| **SLA** | 99.5% uptime |
| **Contact** | #backend-team Slack |

---

### search-service
| Field | Value |
|-------|-------|
| **Owner** | Backend Team (Alice Wong) |
| **Repository** | github.com/example-org/search-service |
| **Status** | EXISTING (Production) |
| **Language** | Java 17 |
| **Last ADR** | ADR-015 (Elasticsearch Integration) |
| **API Version** | v1.2 (OpenAPI 3.1) |
| **Dependencies** | Elasticsearch, PostgreSQL |
| **Deployment** | Kubernetes (AWS EKS) |
| **SLA** | 99.9% uptime |
| **Contact** | #backend-team Slack |

---

### web-frontend
| Field | Value |
|-------|-------|
| **Owner** | Frontend Team (Carol Davis) |
| **Repository** | github.com/example-org/web-frontend |
| **Status** | EXISTING (Production) |
| **Language** | TypeScript 5 / React 18 |
| **Last ADR** | ADR-020 (Component Architecture) |
| **Build Tool** | Webpack 5 |
| **Dependencies** | API Gateway |
| **Deployment** | CloudFront + S3 (AWS) |
| **SLA** | N/A (Static files cached) |
| **Contact** | #frontend-team Slack |

---

### mobile-app
| Field | Value |
|-------|-------|
| **Owner** | Mobile Team (Derek Brown) |
| **Repository** | github.com/example-org/mobile-app |
| **Status** | EXISTING (Production) |
| **Language** | TypeScript / React Native |
| **Last ADR** | ADR-022 (Native Module Bridge) |
| **Min SDK** | iOS 14, Android 10 |
| **Dependencies** | API Gateway, Native APIs |
| **Distribution** | App Store, Google Play |
| **SLA** | N/A (App-level) |
| **Contact** | #mobile-team Slack |

---

## Planned Services (Backlog)

### payment-service
| Field | Value |
|-------|-------|
| **Owner** | TBD |
| **Repository** | github.com/example-org/payment-service |
| **Status** | NEW (Planned Sprint 26) |
| **Language** | Java 17 (planned) |
| **Planned ADR** | ADR-025 (Stripe Integration) |
| **Expected Launch** | Q3 2026 |
| **Dependencies** | Stripe API, PostgreSQL |

---

## Deprecated Services

### legacy-auth
| Field | Value |
|-------|-------|
| **Status** | DEPRECATED (as of 2026-01-15) |
| **Replacement** | auth-service (ADR-005) |
| **Sunset Date** | 2026-06-30 |
| **Migration** | 95% migrated; 5% legacy clients remain |

---

## Health Status
```
2026-04-10 14:22:00 UTC
├─ auth-service: ✓ UP (p99 latency: 45ms)
├─ profile-service: ✓ UP (p99 latency: 120ms)
├─ notification-service: ✓ UP (messages queued: 234)
├─ search-service: ✓ UP (p99 latency: 250ms)
├─ web-frontend: ✓ UP (cache hit rate: 94%)
└─ mobile-app: ✓ UP (active sessions: 12,000)
```

---

**Next Update**: [date + 1 week]
