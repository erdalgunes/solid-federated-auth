# SolidAuth Threat Model

## Executive Summary

This document provides a comprehensive threat model for the SolidAuth decentralized authentication gateway using STRIDE methodology. It identifies potential threats, defines security boundaries, and specifies mitigations to ensure secure operation while maintaining user sovereignty through Solid-OIDC.

## System Overview

SolidAuth acts as an authentication gateway between client applications and Solid OIDC providers, abstracting the complexity of decentralized authentication while maintaining security guarantees.

### Key Assets to Protect

1. **User Credentials & Tokens**
   - WebID credentials
   - Access tokens
   - Refresh tokens
   - DPoP keys
   - Session identifiers

2. **Application Secrets**
   - API keys
   - Client secrets
   - Signing keys
   - Database credentials

3. **User Privacy**
   - Authentication patterns
   - WebID profiles
   - Authorization scopes
   - Session metadata

4. **System Integrity**
   - Gateway availability
   - Data consistency
   - Audit logs
   - Configuration

## Threat Actors

### External Actors

1. **Anonymous Attackers**
   - Motivation: Disruption, data theft, system compromise
   - Capabilities: Public internet access, common attack tools
   - Targets: Public APIs, authentication endpoints

2. **Malicious Applications**
   - Motivation: Steal user credentials, impersonate users
   - Capabilities: Registered application access, API keys
   - Targets: OAuth flows, token endpoints

3. **Compromised Users**
   - Motivation: Access other users' data, privilege escalation
   - Capabilities: Valid credentials, authenticated sessions
   - Targets: Authorization boundaries, session management

4. **Nation-State Actors**
   - Motivation: Mass surveillance, targeted attacks
   - Capabilities: Advanced persistent threats, zero-days
   - Targets: Infrastructure, cryptographic systems

### Internal Actors

1. **Malicious Insiders**
   - Motivation: Data exfiltration, sabotage
   - Capabilities: System access, knowledge of internals
   - Targets: Database, configuration, logs

2. **Compromised Components**
   - Motivation: Lateral movement, persistence
   - Capabilities: Varies by component
   - Targets: Other system components, data stores

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                    UNTRUSTED ZONE                           │
│                  (Internet/Clients)                         │
│                                                             │
│  • Client Applications                                      │
│  • End Users                                                │
│  • Public Networks                                          │
└─────────────────────────┬───────────────────────────────────┘
                          │ TB1: Public API
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  SEMI-TRUSTED ZONE                          │
│                  (Gateway Perimeter)                        │
│                                                             │
│  • API Gateway                                              │
│  • Rate Limiters                                            │
│  • Input Validators                                         │
│  • CORS Handlers                                            │
└─────────────────────────┬───────────────────────────────────┘
                          │ TB2: Authentication Layer
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    TRUSTED ZONE                             │
│                 (Core Authentication)                       │
│                                                             │
│  • Authentication Engine                                    │
│  • Session Manager                                          │
│  • Token Handler                                            │
│  • WebID Validator                                          │
└─────────────────────────┬───────────────────────────────────┘
                          │ TB3: Data Layer
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  HIGHLY TRUSTED ZONE                        │
│                    (Data Storage)                           │
│                                                             │
│  • PostgreSQL (App Registry)                                │
│  • Redis (Session Cache)                                    │
│  • Key Management                                           │
│  • Audit Logs                                               │
└─────────────────────────┬───────────────────────────────────┘
                          │ TB4: External Services
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 EXTERNAL TRUSTED ZONE                       │
│                  (Solid Providers)                          │
│                                                             │
│  • Inrupt Pod Spaces                                        │
│  • Solidcommunity.net                                       │
│  • Self-hosted Pods                                         │
└─────────────────────────────────────────────────────────────┘
```

### Trust Boundary Controls

**TB1: Public API**
- TLS 1.3 mandatory
- Rate limiting per IP/API key
- Input validation on all parameters
- CORS policy enforcement

**TB2: Authentication Layer**
- Token validation
- Session verification
- CSRF protection
- Authorization checks

**TB3: Data Layer**
- Encrypted connections
- Prepared statements
- Access control lists
- Encryption at rest

**TB4: External Services**
- Certificate pinning
- DPoP validation
- Response validation
- Timeout controls

## STRIDE Analysis

### 1. Spoofing

#### S1.1: Client Application Spoofing
- **Threat**: Malicious app impersonates legitimate application
- **Component**: API Gateway
- **Impact**: Unauthorized access to user data
- **Likelihood**: High
- **Mitigations**:
  - Strong API key validation
  - Client certificate authentication (optional)
  - Application allowlisting
  - Redirect URI validation

#### S1.2: User Identity Spoofing
- **Threat**: Attacker impersonates legitimate user
- **Component**: Authentication Engine
- **Impact**: Unauthorized access to user resources
- **Likelihood**: Medium
- **Mitigations**:
  - WebID verification with proof of possession
  - DPoP token binding
  - Multi-factor authentication support
  - Session fingerprinting

#### S1.3: Provider Spoofing
- **Threat**: Fake Solid provider in authentication flow
- **Component**: Provider Interaction
- **Impact**: Credential theft
- **Likelihood**: Low
- **Mitigations**:
  - Provider allowlisting
  - Certificate validation
  - Well-known endpoint verification
  - DNS-over-HTTPS

### 2. Tampering

#### T2.1: Token Tampering
- **Threat**: Modification of JWT tokens in transit/storage
- **Component**: Token Handler
- **Impact**: Privilege escalation
- **Likelihood**: Low
- **Mitigations**:
  - Token signature verification
  - JWE for sensitive claims
  - Token binding to sessions
  - Short token lifetimes

#### T2.2: Session Data Tampering
- **Threat**: Modification of session data in Redis
- **Component**: Session Cache
- **Impact**: Session hijacking
- **Likelihood**: Low
- **Mitigations**:
  - Authenticated Redis connections
  - Session data signing
  - Integrity checks
  - Network segmentation

#### T2.3: Configuration Tampering
- **Threat**: Unauthorized modification of gateway configuration
- **Component**: Configuration Management
- **Impact**: System compromise
- **Likelihood**: Low
- **Mitigations**:
  - Configuration signing
  - File integrity monitoring
  - Version control
  - Deployment automation

### 3. Repudiation

#### R3.1: Authentication Repudiation
- **Threat**: User denies authentication attempt
- **Component**: Audit System
- **Impact**: Dispute resolution failures
- **Likelihood**: Medium
- **Mitigations**:
  - Comprehensive audit logging
  - Log signing and timestamping
  - Centralized log aggregation
  - Legal compliance logging

#### R3.2: Authorization Repudiation
- **Threat**: Application denies authorization request
- **Component**: Authorization Engine
- **Impact**: Access control disputes
- **Likelihood**: Low
- **Mitigations**:
  - Authorization event logging
  - Consent proof storage
  - Request/response logging
  - Immutable audit trail

### 4. Information Disclosure

#### I4.1: Token Leakage
- **Threat**: Exposure of authentication tokens
- **Component**: API Layer
- **Impact**: Account takeover
- **Likelihood**: Medium
- **Mitigations**:
  - Tokens in Authorization headers only
  - No tokens in URLs or logs
  - Secure token storage in SDKs
  - Token encryption at rest

#### I4.2: User Profile Leakage
- **Threat**: Unauthorized access to WebID profiles
- **Component**: WebID Validator
- **Impact**: Privacy violation
- **Likelihood**: Medium
- **Mitigations**:
  - Minimal profile fetching
  - Profile caching controls
  - Access control enforcement
  - Data minimization

#### I4.3: System Information Leakage
- **Threat**: Exposure of system internals via errors
- **Component**: Error Handling
- **Impact**: Information for further attacks
- **Likelihood**: High
- **Mitigations**:
  - Generic error messages to clients
  - Detailed logging server-side only
  - Stack trace suppression
  - Security headers

### 5. Denial of Service

#### D5.1: API Exhaustion
- **Threat**: Resource exhaustion via API abuse
- **Component**: API Gateway
- **Impact**: Service unavailability
- **Likelihood**: High
- **Mitigations**:
  - Rate limiting per endpoint
  - Request throttling
  - Captcha for suspicious activity
  - DDoS protection

#### D5.2: State Exhaustion
- **Threat**: Session/cache exhaustion attacks
- **Component**: Session Manager
- **Impact**: Memory exhaustion
- **Likelihood**: Medium
- **Mitigations**:
  - Session limits per user
  - Automatic session cleanup
  - Cache eviction policies
  - Resource quotas

#### D5.3: Computational DoS
- **Threat**: CPU exhaustion via expensive operations
- **Component**: Cryptographic Operations
- **Impact**: Service degradation
- **Likelihood**: Low
- **Mitigations**:
  - Operation timeouts
  - Async processing
  - Computational limits
  - Load balancing

### 6. Elevation of Privilege

#### E6.1: Privilege Escalation via JWT
- **Threat**: Manipulation of JWT claims for higher privileges
- **Component**: Token Validation
- **Impact**: Unauthorized access
- **Likelihood**: Low
- **Mitigations**:
  - Strict claim validation
  - Principle of least privilege
  - Role-based access control
  - Claim allowlisting

#### E6.2: SQL Injection
- **Threat**: Database query manipulation
- **Component**: Data Layer
- **Impact**: Data breach
- **Likelihood**: Low
- **Mitigations**:
  - Parameterized queries only
  - ORM usage
  - Input validation
  - Database permissions

#### E6.3: SSRF Attacks
- **Threat**: Server-side request forgery to internal services
- **Component**: Provider Interaction
- **Impact**: Internal network access
- **Likelihood**: Medium
- **Mitigations**:
  - URL allowlisting
  - Network segmentation
  - Egress filtering
  - Response validation

## Security Controls Matrix

| Control Category | Implementation | Priority | Status |
|-----------------|----------------|----------|---------|
| **Authentication** |
| WebID Verification | Cryptographic proof validation | Critical | Required |
| DPoP Support | Token binding to key proof | Critical | Required |
| MFA Support | TOTP/WebAuthn integration | High | Planned |
| Session Management | Secure session lifecycle | Critical | Required |
| **Authorization** |
| RBAC | Role-based access control | High | Required |
| Scope Validation | OAuth scope enforcement | Critical | Required |
| Consent Management | User consent tracking | High | Required |
| Policy Engine | Fine-grained policies | Medium | Future |
| **Cryptography** |
| TLS 1.3 | Transport encryption | Critical | Required |
| Token Signing | RS256/ES256 signatures | Critical | Required |
| Key Rotation | Automatic key lifecycle | High | Required |
| Encryption at Rest | Database/cache encryption | High | Required |
| **Input Validation** |
| Parameter Validation | Type/format checking | Critical | Required |
| SQL Injection Prevention | Parameterized queries | Critical | Required |
| XSS Prevention | Output encoding | Critical | Required |
| CSRF Protection | Token validation | Critical | Required |
| **Monitoring** |
| Audit Logging | Comprehensive event logs | Critical | Required |
| Security Monitoring | Threat detection | High | Required |
| Performance Monitoring | Latency/throughput metrics | Medium | Required |
| Alerting | Real-time notifications | High | Required |
| **Incident Response** |
| Incident Playbooks | Response procedures | High | Required |
| Forensics Capability | Evidence collection | Medium | Planned |
| Backup/Recovery | Data restoration | High | Required |
| Communication Plan | Stakeholder notification | Medium | Required |

## Attack Scenarios

### Scenario 1: Malicious Application Attack
```
1. Attacker registers malicious application
2. Tricks user into authorizing excessive scopes
3. Uses tokens to access user's Solid Pod
4. Exfiltrates sensitive data

Mitigations:
- Scope review UI for users
- Application review process
- Anomaly detection
- Token usage monitoring
```

### Scenario 2: Token Relay Attack
```
1. Attacker intercepts access token
2. Attempts to use token from different context
3. Bypasses basic bearer token validation
4. Gains unauthorized access

Mitigations:
- DPoP mandatory for sensitive operations
- Token binding to client
- Short token lifetimes
- Refresh token rotation
```

### Scenario 3: Session Fixation
```
1. Attacker obtains valid session ID
2. Tricks victim into using fixed session
3. Victim authenticates with fixed session
4. Attacker hijacks authenticated session

Mitigations:
- Session regeneration on auth
- Session binding to client
- Secure session cookies
- Session timeout
```

## Formal Verification Preparation

### ProVerif Model Inputs

```proverif
(* Types *)
type key.
type nonce.
type token.
type webid.

(* Channels *)
free c: channel.
private free secure: channel.

(* Functions *)
fun sign(bitstring, key): bitstring.
fun verify(bitstring, key): bool.
fun encrypt(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; decrypt(encrypt(m, k), k) = m.

(* Events *)
event ClientAuthorized(webid).
event TokenIssued(token).
event SessionEstablished(bitstring).
event AccessGranted(webid, bitstring).

(* Security Properties *)
query attacker(token).
query id: webid; event(AccessGranted(id, scope)) ==> event(ClientAuthorized(id)).

(* Protocol *)
let Client(id: webid, sk: key) =
  new n: nonce;
  out(c, (id, n));
  in(c, challenge: bitstring);
  let response = sign((challenge, n), sk) in
  out(c, response).

let Gateway() =
  in(c, (id: webid, n: nonce));
  new challenge: nonce;
  out(c, challenge);
  in(c, response: bitstring);
  if verify(response, pk(id)) then
    new t: token;
    event TokenIssued(t);
    event ClientAuthorized(id);
    out(secure, encrypt(t, sessionKey)).

(* Main *)
process
  (!Client(alice, sk_alice)) |
  (!Gateway()) |
  (!Attacker())
```

### Security Properties to Verify

1. **Authentication**: Every access grant must be preceded by proper authentication
2. **Confidentiality**: Tokens must not be accessible to attackers
3. **Integrity**: Messages cannot be tampered without detection
4. **Non-repudiation**: Authentication events are undeniable
5. **Liveness**: Protocol completes under honest conditions

## Compliance Requirements

### OWASP Top 10 Coverage

| Risk | Coverage | Implementation |
|------|----------|----------------|
| A01: Broken Access Control | ✅ | RBAC, scope validation |
| A02: Cryptographic Failures | ✅ | TLS 1.3, strong algorithms |
| A03: Injection | ✅ | Parameterized queries, validation |
| A04: Insecure Design | ✅ | Threat modeling, secure architecture |
| A05: Security Misconfiguration | ✅ | Hardening, secure defaults |
| A06: Vulnerable Components | ✅ | Dependency scanning, updates |
| A07: Authentication Failures | ✅ | DPoP, session management |
| A08: Data Integrity Failures | ✅ | Signing, integrity checks |
| A09: Logging Failures | ✅ | Comprehensive audit logs |
| A10: SSRF | ✅ | URL validation, allowlisting |

### OAuth 2.0 Security BCP (RFC 8252)

- ✅ PKCE for public clients
- ✅ Exact redirect URI matching
- ✅ State parameter mandatory
- ✅ Token binding support
- ✅ Refresh token rotation

### GDPR Compliance

- ✅ Data minimization
- ✅ Purpose limitation
- ✅ Consent management
- ✅ Right to erasure
- ✅ Data portability

## Risk Matrix

| Threat | Likelihood | Impact | Risk Level | Mitigation Priority |
|--------|------------|--------|------------|-------------------|
| API Exhaustion | High | Medium | High | Critical |
| Token Leakage | Medium | High | High | Critical |
| Client Spoofing | High | Medium | High | Critical |
| SQL Injection | Low | Critical | Medium | High |
| SSRF Attacks | Medium | Medium | Medium | High |
| Config Tampering | Low | High | Medium | Medium |
| Session Fixation | Low | Medium | Low | Medium |
| Provider Spoofing | Low | High | Medium | High |

## Implementation Priorities

### Phase 1: Critical Security (Week 1)
- [ ] TLS configuration
- [ ] Input validation framework
- [ ] Basic rate limiting
- [ ] Session management
- [ ] Audit logging

### Phase 2: Authentication Security (Week 2)
- [ ] DPoP implementation
- [ ] WebID verification
- [ ] Token validation
- [ ] CSRF protection
- [ ] Provider validation

### Phase 3: Advanced Security (Week 3)
- [ ] Anomaly detection
- [ ] Security monitoring
- [ ] Automated responses
- [ ] Incident response procedures
- [ ] Security testing

### Phase 4: Compliance & Verification (Week 4)
- [ ] OWASP compliance validation
- [ ] ProVerif formal verification
- [ ] Security audit
- [ ] Documentation completion
- [ ] Penetration testing

## Security Testing Plan

### Unit Security Tests
- Input validation boundaries
- Cryptographic operations
- Token validation logic
- Session management

### Integration Security Tests
- Authentication flows
- Authorization checks
- Cross-component communication
- External provider interaction

### Security Scenarios
- Attack simulation
- Penetration testing
- Fuzzing
- Load testing with malicious patterns

## Incident Response Plan

### Detection
- Real-time monitoring alerts
- Anomaly detection systems
- User reports
- Security audits

### Response
1. Incident classification
2. Containment measures
3. Evidence collection
4. Eradication
5. Recovery
6. Post-incident review

### Communication
- Internal team notification
- User communication (if affected)
- Regulatory notification (if required)
- Public disclosure (responsible disclosure)

## Conclusion

This threat model provides comprehensive security analysis for the SolidAuth gateway. Implementation of identified controls and mitigations will ensure a secure authentication service that maintains user sovereignty while providing enterprise-grade security.

Regular reviews and updates of this threat model should be conducted as the system evolves and new threats emerge.