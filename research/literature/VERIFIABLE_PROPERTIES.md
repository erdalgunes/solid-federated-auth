# Verifiable Security Properties for Solid-OIDC Authentication Gateway

## Overview

This document defines the security properties that should be formally verified for the Solid-OIDC authentication gateway. Properties are categorized by priority and verification complexity.

## 1. Fundamental Security Properties

### 1.1 Secrecy Properties

#### Token Secrecy
- **Property**: Access tokens remain secret between authorized parties
- **ProVerif Query**: `query attacker(access_token).`
- **Threat Model**: Dolev-Yao attacker on network
- **Priority**: Critical

#### Refresh Token Secrecy
- **Property**: Refresh tokens never exposed to unauthorized parties
- **ProVerif Query**: `query attacker(refresh_token).`
- **Threat Model**: Compromised network, not client
- **Priority**: Critical

#### Client Secret Protection
- **Property**: Client credentials remain confidential
- **ProVerif Query**: `query attacker(client_secret).`
- **Threat Model**: Network attacker
- **Priority**: Critical

### 1.2 Authentication Properties

#### Client Authentication
- **Property**: Server correctly authenticates client identity
- **ProVerif Event**: `event clientAuthenticated(client_id)`
- **Correspondence**: `event acceptsClient(c) ==> event clientRegistered(c)`
- **Priority**: Critical

#### User Authentication
- **Property**: Gateway correctly authenticates resource owner
- **ProVerif Event**: `event userAuthenticated(user_id)`
- **Correspondence**: `event acceptsUser(u) ==> event userExists(u)`
- **Priority**: Critical

#### Mutual Authentication
- **Property**: Both parties authenticate each other
- **ProVerif Query**: Correspondence assertions
- **Priority**: High

### 1.3 Integrity Properties

#### Message Integrity
- **Property**: Protocol messages cannot be tampered
- **Verification**: MAC/signature verification
- **Priority**: Critical

#### Authorization Code Integrity
- **Property**: Authorization codes cannot be modified
- **ProVerif**: Non-malleability check
- **Priority**: Critical

## 2. Authorization Properties

### 2.1 Scope Enforcement

#### Scope Compliance
- **Property**: Issued tokens respect requested scopes
- **Formal Model**: `issued_scope ⊆ requested_scope`
- **Priority**: High

#### Scope Downgrading
- **Property**: Refresh tokens cannot upgrade scopes
- **Formal Model**: `refreshed_scope ⊆ original_scope`
- **Priority**: High

### 2.2 Consent Properties

#### Explicit Consent
- **Property**: User consent required for authorization
- **ProVerif Event**: `event userConsent(user, client, scope)`
- **Priority**: High

#### Consent Revocation
- **Property**: Revoked consent invalidates tokens
- **Temporal Property**: `G(revoked(consent) → F(invalid(token)))`
- **Priority**: Medium

## 3. Session Properties

### 3.1 Session Security

#### Session Binding
- **Property**: Tokens bound to correct session
- **Verification**: Session identifier matching
- **Priority**: High

#### Session Fixation Prevention
- **Property**: Cannot fixate another user's session
- **Attack Model**: Pre-authentication attacker
- **Priority**: Critical

### 3.2 CSRF Protection

#### State Parameter Validation
- **Property**: State parameter prevents CSRF
- **ProVerif**: Freshness and binding check
- **Priority**: Critical

#### Origin Validation
- **Property**: Requests validated against origin
- **Priority**: High

## 4. Token Lifecycle Properties

### 4.1 Token Issuance

#### Token Uniqueness
- **Property**: Each token is unique
- **Formal Model**: `∀t1,t2: issued(t1) ∧ issued(t2) ∧ t1.value = t2.value → t1 = t2`
- **Priority**: High

#### Token Freshness
- **Property**: Tokens include fresh nonces
- **ProVerif**: Freshness declaration
- **Priority**: High

### 4.2 Token Expiration

#### Expiration Enforcement
- **Property**: Expired tokens rejected
- **Temporal Logic**: `G(current_time > token.exp → ¬valid(token))`
- **Priority**: Critical

#### Refresh Token Rotation
- **Property**: Used refresh tokens invalidated
- **Priority**: High

### 4.3 Token Revocation

#### Immediate Revocation
- **Property**: Revoked tokens immediately invalid
- **Temporal Logic**: `G(revoked(token) → F(¬valid(token)))`
- **Priority**: High

#### Cascading Revocation
- **Property**: Revoking refresh token revokes access tokens
- **Priority**: Medium

## 5. Privacy Properties

### 5.1 Unlinkability

#### Session Unlinkability
- **Property**: Cannot link user sessions
- **ProVerif**: Observational equivalence
- **Priority**: Medium

#### Cross-Client Unlinkability
- **Property**: Cannot track user across clients
- **Priority**: Medium

### 5.2 Anonymity

#### User Anonymity
- **Property**: User identity hidden from unauthorized parties
- **Verification**: Information flow analysis
- **Priority**: Medium

#### Selective Disclosure
- **Property**: Minimal information disclosure
- **Priority**: Low

## 6. Solid-Specific Properties

### 6.1 WebID Properties

#### WebID Authentication
- **Property**: Correct WebID verification
- **Model**: WebID-TLS or WebID-OIDC flow
- **Priority**: Critical

#### WebID Uniqueness
- **Property**: One WebID per identity
- **Priority**: High

### 6.2 Pod Access Control

#### Pod Authorization
- **Property**: Access respects pod ACL
- **Formal Model**: ACL enforcement rules
- **Priority**: Critical

#### Cross-Pod Authentication
- **Property**: Authentication works across pods
- **Priority**: High

### 6.3 Decentralization Properties

#### No Single Point of Failure
- **Property**: System remains secure with node failures
- **Model**: Distributed system properties
- **Priority**: High

#### Identity Portability
- **Property**: Identity can migrate between providers
- **Priority**: Medium

## 7. Attack Resistance Properties

### 7.1 Common Attacks

#### Replay Attack Resistance
- **Property**: Cannot replay authentication messages
- **Verification**: Nonce/timestamp checking
- **Priority**: Critical

#### Man-in-the-Middle Resistance
- **Property**: MITM cannot impersonate parties
- **Priority**: Critical

#### Injection Attack Resistance
- **Property**: Cannot inject malicious tokens/codes
- **Priority**: Critical

### 7.2 OAuth-Specific Attacks

#### Authorization Code Injection
- **Property**: Cannot use stolen authorization codes
- **PKCE**: Code verifier validation
- **Priority**: Critical

#### Token Substitution
- **Property**: Cannot substitute tokens between sessions
- **Priority**: High

#### Open Redirect Prevention
- **Property**: Redirect URIs properly validated
- **Priority**: Critical

## 8. Verification Methodology

### 8.1 ProVerif Verification

```proverif
(* Core secrecy properties *)
query attacker(access_token).
query attacker(refresh_token).
query attacker(client_secret).

(* Authentication correspondences *)
event clientAuth(bitstring).
event serverAccept(bitstring).
query x:bitstring; event(serverAccept(x)) ==> event(clientAuth(x)).

(* Injective correspondence for replay prevention *)
query x:bitstring; inj-event(serverAccept(x)) ==> inj-event(clientAuth(x)).
```

### 8.2 Tamarin Verification

```tamarin
/* State-based properties */
lemma token_expiration:
  "All token t #i #j. 
    Issued(token, t) @ #i & 
    Expired(token) @ #j & 
    #i < #j
    ==> not(Ex #k. Valid(token) @ #k & #j < #k)"

/* Privacy via observational equivalence */
lemma user_unlinkability:
  exists-trace
    "Ex u1 u2 #i #j.
      UserSession(u1) @ #i &
      UserSession(u2) @ #j &
      not(u1 = u2)"
```

### 8.3 TLA+ Specification

```tla
(* Temporal properties *)
TokenExpiration == 
  [](\A t \in Tokens : 
    (t.expiry < CurrentTime) => ~t.valid)

SessionConsistency ==
  [](\A s \in Sessions :
    s.token.session_id = s.id)
```

## 9. Property Priority Matrix

| Property Category | Critical | High | Medium | Low |
|------------------|----------|------|--------|-----|
| Secrecy | 3 | 0 | 0 | 0 |
| Authentication | 2 | 1 | 0 | 0 |
| Authorization | 0 | 2 | 1 | 0 |
| Session | 2 | 2 | 0 | 0 |
| Token Lifecycle | 2 | 3 | 1 | 0 |
| Privacy | 0 | 0 | 3 | 1 |
| Solid-Specific | 2 | 2 | 1 | 0 |
| Attack Resistance | 5 | 1 | 0 | 0 |

## 10. Verification Phases

### Phase 1: Core Security (Weeks 1-2)
- All Critical properties
- Basic ProVerif models
- Automated verification

### Phase 2: Extended Properties (Weeks 3-4)
- High priority properties
- Tamarin for state properties
- Manual proof guidance

### Phase 3: Advanced Analysis (Week 5)
- Medium/Low priority
- Privacy properties
- Performance impact

### Phase 4: Solid-Specific (Week 6)
- WebID verification
- Decentralization properties
- Cross-pod scenarios

## 11. Success Criteria

### Minimum Requirements
- All Critical properties verified
- No false positives in verification
- Automated verification scripts

### Target Goals
- 90% of High priority verified
- Privacy properties proven
- Attack scenarios tested

### Stretch Goals
- Full formal proof of all properties
- Performance bounds proven
- Comparison with Auth0/Keycloak

## 12. Documentation Requirements

For each verified property:
1. Formal specification
2. ProVerif/Tamarin model
3. Verification output
4. Attack scenarios (if found)
5. Mitigation strategies

## Conclusion

This comprehensive list of verifiable properties provides a roadmap for formal verification of the Solid-OIDC gateway. Starting with critical security properties and progressing through advanced privacy and Solid-specific properties ensures systematic and thorough analysis suitable for academic publication.

---

*Document Version*: 1.0  
*Last Updated*: December 2024  
*Author*: Solid-OIDC Research Team