# SolidAuth Gateway Architecture

## Overview

SolidAuth is a decentralized authentication gateway that provides an Auth0-like developer experience while leveraging Solid-OIDC protocol for user-controlled identity. This document describes the system architecture, component design, and key technical decisions.

## Design Principles

1. **YAGNI-First**: Build only what's needed, add complexity when justified
2. **Developer Experience**: Auth0-like simplicity for integration
3. **User Sovereignty**: Full Solid-OIDC compliance for user control
4. **Security by Design**: Formal verification ready, defense in depth
5. **Monolithic Start**: Single service, modularize when needed

## System Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Applications                   │
│                   (Web, Mobile, Server-side)                 │
└──────────────────┬────────────────────┬────────────────────┘
                   │                    │
                   ▼                    ▼
         ┌─────────────────┐  ┌─────────────────┐
         │  JavaScript SDK  │  │   Python SDK    │
         │   (TypeScript)   │  │   (Future)      │
         └────────┬─────────┘  └────────┬────────┘
                  │                      │
                  ▼                      ▼
┌──────────────────────────────────────────────────────────────┐
│                      SolidAuth Gateway                       │
│                       (FastAPI/Python)                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    API Layer                          │  │
│  │  - REST endpoints for authentication                  │  │
│  │  - Session management                                 │  │
│  │  - Application registration                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                Authentication Engine                  │  │
│  │  - Solid-OIDC flow orchestration                     │  │
│  │  - WebID discovery and validation                    │  │
│  │  - DPoP token management                             │  │
│  │  - Provider interaction                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Security Layer                       │  │
│  │  - Rate limiting                                      │  │
│  │  - Input validation                                   │  │
│  │  - CSRF protection                                    │  │
│  │  - Audit logging                                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────┬──────────────────────────┬─────────────────────┘
             │                          │
             ▼                          ▼
    ┌────────────────┐        ┌────────────────┐
    │     Redis      │        │   PostgreSQL   │
    │ Session Cache  │        │   App Registry │
    └────────────────┘        └────────────────┘
             │                          
             ▼                          
    ┌────────────────────────────────────────┐
    │        Solid OIDC Providers            │
    │  (Inrupt, Solidcommunity, Self-hosted) │
    └────────────────────────────────────────┘
```

### Component Descriptions

#### 1. SolidAuth Gateway (Core Service)

**Technology**: Python 3.11+ with FastAPI

**Responsibilities**:
- Orchestrate Solid-OIDC authentication flows
- Manage application registrations and API keys
- Handle session management and token lifecycle
- Abstract DPoP complexity from developers
- Provide REST API for client applications

**Key Modules**:
- `auth/`: Authentication flow handlers
- `api/`: REST endpoint definitions
- `security/`: Security middleware and validators
- `storage/`: Database and cache interfaces
- `providers/`: Solid provider interaction logic

#### 2. Client SDKs

**Initial SDK**: TypeScript/JavaScript

**Features**:
- Simple API: `login()`, `logout()`, `getUser()`, `isAuthenticated()`
- Automatic token refresh
- Event-based auth state changes
- Local storage management
- TypeScript type definitions

**Example Usage**:
```typescript
import { SolidAuth } from '@solidauth/sdk';

const auth = new SolidAuth({
  domain: 'your-gateway.example.com',
  clientId: 'your-client-id',
  redirectUri: 'http://localhost:3000/callback'
});

// Login
await auth.login();

// Get user info
const user = await auth.getUser();

// Make authenticated request
const response = await auth.fetch('/api/data');
```

#### 3. Data Storage

**PostgreSQL** (Application Data):
- Application registrations
- API keys and secrets
- Configuration settings
- Audit logs
- Usage metrics

**Redis** (Session Cache):
- User sessions
- Token cache
- Rate limiting counters
- Temporary auth state

#### 4. Security Layer

**Implemented Security Measures**:
- HTTPS only with HSTS headers
- Rate limiting per IP and per user
- Input validation using Pydantic
- CSRF tokens for state-changing operations
- Secure session cookies (httpOnly, secure, sameSite)
- Audit logging for all authentication events

## Authentication Flows

### 1. Developer Registration Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Portal as Dev Portal
    participant GW as Gateway
    participant DB as PostgreSQL

    Dev->>Portal: Register Application
    Portal->>GW: Create App Request
    GW->>DB: Store App Config
    DB-->>GW: App ID + Secret
    GW-->>Portal: Client Credentials
    Portal-->>Dev: Display Credentials
```

### 2. End-User Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant App as Client App
    participant SDK as SDK
    participant GW as Gateway
    participant Redis
    participant SP as Solid Provider

    User->>App: Click Login
    App->>SDK: auth.login()
    SDK->>GW: GET /authorize
    GW->>GW: Generate state
    GW->>Redis: Store state
    GW->>User: Redirect to /login
    
    User->>GW: Enter WebID
    GW->>GW: Discover Provider
    GW->>SP: OIDC Authorization
    SP->>User: Login Page
    User->>SP: Authenticate
    SP->>GW: Authorization Code
    
    GW->>SP: Exchange Code for Tokens
    SP-->>GW: ID Token + Access Token
    GW->>GW: Generate Session
    GW->>Redis: Store Session
    GW->>App: Redirect with Session
    
    App->>SDK: Handle Callback
    SDK->>GW: GET /userinfo
    GW->>Redis: Validate Session
    GW-->>SDK: User Profile
    SDK-->>App: User Object
```

### 3. Token Refresh Flow

```mermaid
sequenceDiagram
    participant SDK
    participant GW as Gateway
    participant Redis
    participant SP as Solid Provider

    SDK->>GW: POST /token/refresh
    GW->>Redis: Get Refresh Token
    GW->>SP: Refresh Token Request
    SP-->>GW: New Tokens
    GW->>Redis: Update Session
    GW-->>SDK: New Access Token
```

## API Specification

### Authentication Endpoints

```yaml
/api/v1/authorize:
  get:
    summary: Initiate authentication flow
    parameters:
      - client_id: string
      - redirect_uri: string
      - scope: string
      - state: string
    responses:
      302: Redirect to login page

/api/v1/login:
  post:
    summary: Process WebID and redirect to provider
    body:
      webid: string
      state: string
    responses:
      302: Redirect to Solid provider

/api/v1/callback:
  get:
    summary: Handle provider callback
    parameters:
      - code: string
      - state: string
    responses:
      302: Redirect to application

/api/v1/token:
  post:
    summary: Exchange code for tokens
    body:
      grant_type: string
      code: string
      client_id: string
      client_secret: string
    responses:
      200: Token response

/api/v1/userinfo:
  get:
    summary: Get user profile
    headers:
      Authorization: Bearer <token>
    responses:
      200: User profile
```

### Management Endpoints

```yaml
/api/v1/apps:
  post:
    summary: Register new application
    body:
      name: string
      redirect_uris: array
      description: string
    responses:
      201: Application created

/api/v1/apps/{app_id}:
  get:
    summary: Get application details
  put:
    summary: Update application
  delete:
    summary: Delete application
```

## Technology Stack

### Core Technologies

| Component | Technology | Justification |
|-----------|------------|---------------|
| Runtime | Python 3.11+ | Async support, type hints, performance |
| Framework | FastAPI | Modern, async, automatic OpenAPI |
| Database | PostgreSQL 15 | JSONB support, reliability, ACID |
| Cache | Redis 7 | Performance, pub/sub, TTL support |
| Container | Docker | Reproducibility, deployment simplicity |

### Python Dependencies

```toml
[dependencies]
fastapi = "^0.104.0"
uvicorn = "^0.24.0"
pydantic = "^2.5.0"
httpx = "^0.25.0"
python-jose = "^3.3.0"
cryptography = "^41.0.0"
redis = "^5.0.0"
asyncpg = "^0.29.0"
sqlalchemy = "^2.0.0"
alembic = "^1.13.0"
python-multipart = "^0.0.6"
passlib = "^1.7.4"
```

### Development Tools

- **Testing**: pytest, pytest-asyncio, httpx
- **Linting**: ruff, mypy, black
- **Documentation**: mkdocs, swagger-ui
- **Monitoring**: Prometheus metrics, structured logging

## Security Architecture

### Threat Model

| Threat | Mitigation |
|--------|------------|
| Token theft | Short-lived tokens, secure storage, HTTPS only |
| Session hijacking | Secure cookies, session binding, IP validation |
| CSRF attacks | State parameter, CSRF tokens, SameSite cookies |
| DPoP key compromise | Key rotation, secure key storage |
| Provider impersonation | Certificate validation, provider allowlist |
| Rate limiting bypass | Distributed rate limiting, IP blocking |

### Security Properties for Formal Verification

1. **Authentication Soundness**: Only legitimate users can authenticate
2. **Session Integrity**: Sessions cannot be hijacked or replayed
3. **Token Confidentiality**: Tokens remain secret during transmission
4. **Non-repudiation**: Authentication events are auditable
5. **Privacy Preservation**: User data is not leaked to unauthorized parties

## Deployment Architecture

### Development Environment

```yaml
# docker-compose.yml
version: '3.8'

services:
  gateway:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres/solidauth
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=solidauth
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### Production Considerations

1. **High Availability**: Multiple gateway instances behind load balancer
2. **Database**: Managed PostgreSQL with read replicas
3. **Caching**: Redis Cluster for session distribution
4. **Monitoring**: Prometheus + Grafana for metrics
5. **Logging**: Structured JSON logs to ELK stack
6. **Secrets**: Environment variables or secret management service

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Authentication latency | < 500ms | P95 end-to-end |
| Token refresh | < 100ms | P95 |
| Concurrent sessions | > 10,000 | Per instance |
| Requests per second | > 1,000 | Per instance |
| Availability | 99.9% | Monthly uptime |

## Extensibility Points

### Future Enhancements (Post-MVP)

1. **Additional SDKs**: Python, Go, Ruby, Java
2. **Protocol Support**: SAML, OAuth 1.0a
3. **MFA Support**: TOTP, WebAuthn, SMS
4. **Analytics Dashboard**: Usage metrics, auth patterns
5. **Webhook Events**: Real-time auth notifications
6. **Federated Gateway**: Multi-region deployment

### Plugin Architecture

```python
# Future plugin interface
class AuthProvider(ABC):
    @abstractmethod
    async def discover(self, webid: str) -> ProviderConfig:
        pass
    
    @abstractmethod
    async def authenticate(self, config: ProviderConfig) -> AuthResult:
        pass
```

## Migration Path

### From Auth0/Okta

1. Export user database
2. Map user attributes to WebID
3. Configure redirect URIs
4. Update SDK integration
5. Gradual migration with dual support

## Monitoring and Observability

### Metrics to Track

- Authentication success/failure rates
- Provider response times
- Session creation/expiration
- Token refresh patterns
- API endpoint latencies
- Error rates by category

### Health Checks

```yaml
/health:
  get:
    summary: Basic health check
    responses:
      200: Service is healthy

/health/ready:
  get:
    summary: Readiness check
    responses:
      200: Service is ready
      503: Service not ready
```

## Conclusion

This architecture provides a solid foundation for building a decentralized authentication gateway that matches the developer experience of centralized services while maintaining user sovereignty. The design follows YAGNI principles, starting simple and adding complexity only when justified by requirements.

The modular structure enables formal verification, performance optimization, and future enhancements without major architectural changes. By abstracting Solid-OIDC complexity behind familiar APIs, we lower the barrier to adoption for decentralized identity.