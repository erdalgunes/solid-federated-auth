# SolidAuth Security Architecture

## Overview

This document defines the security architecture for SolidAuth, implementing defense-in-depth principles to protect user identity, application integrity, and system availability while maintaining Solid-OIDC compliance.

## Security Design Principles

1. **Zero Trust**: Never trust, always verify
2. **Defense in Depth**: Multiple layers of security controls
3. **Least Privilege**: Minimal necessary permissions
4. **Fail Secure**: Secure behavior on failure
5. **Security by Design**: Built-in, not bolted-on
6. **Transparency**: User-visible security state

## Security Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                   Security Perimeter                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Edge Security                       │   │
│  │  • DDoS Protection (CloudFlare/AWS Shield)          │   │
│  │  • Geographic Filtering                             │   │
│  │  • Bot Detection                                    │   │
│  │  • SSL/TLS Termination                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                Network Security                      │   │
│  │  • WAF (Web Application Firewall)                   │   │
│  │  • IDS/IPS (Intrusion Detection/Prevention)         │   │
│  │  • Network Segmentation (VLANs)                     │   │
│  │  • Egress Filtering                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Application Security                    │   │
│  │  • Input Validation & Sanitization                  │   │
│  │  • Output Encoding                                  │   │
│  │  • CSRF Protection                                  │   │
│  │  • Security Headers                                 │   │
│  │  • Rate Limiting                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │             Authentication Security                  │   │
│  │  • WebID Verification                               │   │
│  │  • DPoP Token Binding                               │   │
│  │  • Session Management                               │   │
│  │  • MFA Support                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │             Authorization Security                   │   │
│  │  • RBAC (Role-Based Access Control)                 │   │
│  │  • OAuth Scope Enforcement                          │   │
│  │  • Resource-Level Permissions                       │   │
│  │  • Consent Management                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Data Security                        │   │
│  │  • Encryption at Rest (AES-256)                     │   │
│  │  • Encryption in Transit (TLS 1.3)                  │   │
│  │  • Key Management (HSM/KMS)                         │   │
│  │  • Data Classification                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Monitoring & Audit                      │   │
│  │  • Security Event Logging                           │   │
│  │  • Threat Detection                                 │   │
│  │  • Compliance Monitoring                            │   │
│  │  • Forensics Capability                             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Component Security Architecture

### 1. API Gateway Security

```python
# Security Middleware Stack
class SecurityMiddleware:
    def __init__(self):
        self.middlewares = [
            RateLimiter(requests_per_minute=60),
            InputValidator(strict_mode=True),
            CSRFProtector(token_lifetime=3600),
            SecurityHeaders(),
            AuditLogger()
        ]
    
    async def process_request(self, request):
        for middleware in self.middlewares:
            request = await middleware.process(request)
        return request
```

**Security Controls**:
- Rate limiting: 60 requests/minute per IP, 1000/minute per API key
- Input validation: Type checking, length limits, format validation
- CSRF tokens: Required for state-changing operations
- Security headers: CSP, X-Frame-Options, X-Content-Type-Options
- Audit logging: All authentication attempts and API calls

### 2. Authentication Engine Security

```
┌──────────────────────────────────────────┐
│         Authentication Flow               │
│                                          │
│  1. Client Request                       │
│     ↓                                    │
│  2. Challenge Generation                 │
│     • Nonce creation                     │
│     • State parameter                    │
│     • PKCE challenge                     │
│     ↓                                    │
│  3. Provider Redirect                    │
│     • Provider validation                │
│     • URL verification                   │
│     • Scope validation                   │
│     ↓                                    │
│  4. WebID Authentication                 │
│     • Certificate validation             │
│     • Profile verification               │
│     • DPoP proof                         │
│     ↓                                    │
│  5. Token Generation                     │
│     • JWT signing (RS256)                │
│     • Claims validation                  │
│     • Token binding                      │
│     ↓                                    │
│  6. Session Establishment                │
│     • Session ID generation              │
│     • Fingerprinting                     │
│     • Secure cookie settings             │
└──────────────────────────────────────────┘
```

**DPoP Implementation**:
```python
class DPoPValidator:
    def validate_proof(self, dpop_header: str, http_method: str, http_uri: str):
        # Parse DPoP JWT
        header, payload = self.parse_jwt(dpop_header)
        
        # Verify JWT signature with embedded JWK
        if not self.verify_signature(dpop_header, header['jwk']):
            raise SecurityError("Invalid DPoP signature")
        
        # Verify HTTP method and URI binding
        if payload['htm'] != http_method or payload['htu'] != http_uri:
            raise SecurityError("DPoP binding mismatch")
        
        # Verify freshness (5 minute window)
        if abs(time.time() - payload['iat']) > 300:
            raise SecurityError("DPoP proof expired")
        
        # Verify nonce if required
        if self.nonce_required and not self.verify_nonce(payload.get('nonce')):
            raise SecurityError("Invalid or missing nonce")
        
        # Store jti to prevent replay
        if not self.store_jti(payload['jti'], ttl=300):
            raise SecurityError("DPoP proof replay detected")
        
        return header['jwk']  # Return the key for binding
```

### 3. Session Management Security

```python
class SecureSessionManager:
    def __init__(self):
        self.redis = Redis(
            ssl=True,
            ssl_cert_reqs='required',
            ssl_ca_certs='ca.pem'
        )
        self.encryption_key = self.load_key_from_hsm()
    
    def create_session(self, user_id: str, client_info: dict):
        # Generate cryptographically secure session ID
        session_id = secrets.token_urlsafe(32)
        
        # Create session fingerprint
        fingerprint = self.create_fingerprint(client_info)
        
        # Session data
        session_data = {
            'user_id': user_id,
            'created_at': datetime.utcnow().isoformat(),
            'fingerprint': fingerprint,
            'last_activity': datetime.utcnow().isoformat(),
            'ip_address': client_info['ip'],
            'user_agent': client_info['user_agent']
        }
        
        # Encrypt session data
        encrypted_data = self.encrypt(json.dumps(session_data))
        
        # Store in Redis with TTL
        self.redis.setex(
            f"session:{session_id}",
            timedelta(hours=1),
            encrypted_data
        )
        
        return session_id
    
    def validate_session(self, session_id: str, client_info: dict):
        # Retrieve and decrypt session
        encrypted_data = self.redis.get(f"session:{session_id}")
        if not encrypted_data:
            raise SecurityError("Invalid session")
        
        session_data = json.loads(self.decrypt(encrypted_data))
        
        # Verify fingerprint
        if not self.verify_fingerprint(session_data['fingerprint'], client_info):
            raise SecurityError("Session fingerprint mismatch")
        
        # Check session timeout
        last_activity = datetime.fromisoformat(session_data['last_activity'])
        if datetime.utcnow() - last_activity > timedelta(minutes=15):
            raise SecurityError("Session timeout")
        
        # Update last activity
        session_data['last_activity'] = datetime.utcnow().isoformat()
        encrypted_data = self.encrypt(json.dumps(session_data))
        self.redis.setex(
            f"session:{session_id}",
            timedelta(hours=1),
            encrypted_data
        )
        
        return session_data
```

### 4. Token Security

```python
class TokenManager:
    def __init__(self):
        self.signing_key = self.load_signing_key()
        self.encryption_key = self.load_encryption_key()
    
    def create_access_token(self, user_id: str, scopes: list, dpop_thumbprint: str = None):
        # Token claims
        claims = {
            'sub': user_id,
            'iss': 'https://auth.solidauth.com',
            'aud': 'https://api.solidauth.com',
            'exp': int(time.time()) + 3600,  # 1 hour
            'iat': int(time.time()),
            'jti': secrets.token_urlsafe(16),
            'scopes': scopes
        }
        
        # Add DPoP binding if provided
        if dpop_thumbprint:
            claims['cnf'] = {'jkt': dpop_thumbprint}
        
        # Sign token
        token = jwt.encode(claims, self.signing_key, algorithm='RS256')
        
        # Log token issuance
        self.audit_log('token_issued', {
            'user_id': user_id,
            'jti': claims['jti'],
            'scopes': scopes
        })
        
        return token
    
    def validate_token(self, token: str, required_scopes: list = None, dpop_proof: str = None):
        try:
            # Decode and verify signature
            claims = jwt.decode(
                token,
                self.public_key,
                algorithms=['RS256'],
                audience='https://api.solidauth.com',
                issuer='https://auth.solidauth.com'
            )
            
            # Check token binding if DPoP is provided
            if dpop_proof and 'cnf' in claims:
                dpop_key = self.extract_dpop_key(dpop_proof)
                expected_thumbprint = claims['cnf']['jkt']
                actual_thumbprint = self.calculate_thumbprint(dpop_key)
                if expected_thumbprint != actual_thumbprint:
                    raise SecurityError("DPoP binding mismatch")
            
            # Verify scopes
            if required_scopes:
                token_scopes = set(claims.get('scopes', []))
                if not set(required_scopes).issubset(token_scopes):
                    raise SecurityError("Insufficient scopes")
            
            # Check if token is revoked
            if self.is_token_revoked(claims['jti']):
                raise SecurityError("Token revoked")
            
            return claims
            
        except jwt.ExpiredSignatureError:
            raise SecurityError("Token expired")
        except jwt.InvalidTokenError as e:
            raise SecurityError(f"Invalid token: {e}")
```

### 5. Cryptographic Security

```python
class CryptoManager:
    def __init__(self):
        # Key rotation schedule
        self.key_rotation_interval = timedelta(days=90)
        self.algorithm_suite = {
            'signing': 'RS256',
            'encryption': 'AES-256-GCM',
            'hashing': 'SHA-256',
            'kdf': 'PBKDF2'
        }
    
    def rotate_keys(self):
        """Automatic key rotation"""
        # Generate new key pair
        new_key = self.generate_key_pair()
        
        # Store with version
        key_version = int(time.time())
        self.store_key(new_key, key_version)
        
        # Keep old key for grace period
        self.mark_key_for_rotation(key_version - 1)
        
        # Schedule deletion of old keys
        self.schedule_key_deletion(key_version - 2)
    
    def encrypt_sensitive_data(self, data: bytes) -> bytes:
        """Encrypt sensitive data with AES-256-GCM"""
        # Generate nonce
        nonce = os.urandom(12)
        
        # Create cipher
        cipher = Cipher(
            algorithms.AES(self.data_key),
            modes.GCM(nonce),
            backend=default_backend()
        )
        
        # Encrypt
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(data) + encryptor.finalize()
        
        # Return nonce + ciphertext + tag
        return nonce + ciphertext + encryptor.tag
    
    def generate_secure_random(self, length: int) -> str:
        """Generate cryptographically secure random string"""
        return secrets.token_urlsafe(length)
```

### 6. Input Validation Security

```python
class InputValidator:
    def __init__(self):
        self.validators = {
            'webid': self.validate_webid,
            'email': self.validate_email,
            'url': self.validate_url,
            'token': self.validate_token_format,
            'scope': self.validate_scope
        }
    
    def validate_webid(self, webid: str) -> str:
        """Validate and sanitize WebID URL"""
        # Must be HTTPS
        if not webid.startswith('https://'):
            raise ValidationError("WebID must use HTTPS")
        
        # Parse and validate URL structure
        parsed = urlparse(webid)
        if not parsed.netloc or not parsed.path:
            raise ValidationError("Invalid WebID URL structure")
        
        # Check for path traversal attempts
        if '..' in parsed.path or '//' in parsed.path:
            raise ValidationError("Invalid path in WebID")
        
        # Validate against allowlist if configured
        if self.webid_allowlist and parsed.netloc not in self.webid_allowlist:
            raise ValidationError("WebID provider not allowed")
        
        # Return sanitized URL
        return urlunparse(parsed)
    
    def validate_request(self, request_data: dict, schema: dict):
        """Validate request against schema"""
        for field, rules in schema.items():
            value = request_data.get(field)
            
            # Check required fields
            if rules.get('required') and value is None:
                raise ValidationError(f"Missing required field: {field}")
            
            # Type validation
            if value is not None and 'type' in rules:
                if not isinstance(value, rules['type']):
                    raise ValidationError(f"Invalid type for {field}")
            
            # Length validation
            if 'max_length' in rules and len(str(value)) > rules['max_length']:
                raise ValidationError(f"Field {field} exceeds maximum length")
            
            # Pattern validation
            if 'pattern' in rules and not re.match(rules['pattern'], str(value)):
                raise ValidationError(f"Field {field} format invalid")
            
            # Custom validator
            if 'validator' in rules:
                self.validators[rules['validator']](value)
```

### 7. Security Monitoring & Audit

```python
class SecurityMonitor:
    def __init__(self):
        self.alert_thresholds = {
            'failed_auth_attempts': 5,
            'rate_limit_violations': 10,
            'invalid_token_attempts': 3,
            'suspicious_patterns': 1
        }
        self.time_window = 300  # 5 minutes
    
    def monitor_authentication(self, event: dict):
        """Monitor authentication events for anomalies"""
        user_id = event.get('user_id')
        ip_address = event.get('ip_address')
        
        # Check failed attempts
        if event['type'] == 'auth_failed':
            count = self.count_events('auth_failed', user_id, self.time_window)
            if count >= self.alert_thresholds['failed_auth_attempts']:
                self.trigger_alert('excessive_failed_auth', {
                    'user_id': user_id,
                    'attempts': count,
                    'ip_address': ip_address
                })
                self.block_temporarily(user_id, duration=900)  # 15 minutes
        
        # Check for credential stuffing
        if self.detect_credential_stuffing(ip_address):
            self.trigger_alert('credential_stuffing_detected', {
                'ip_address': ip_address
            })
            self.block_ip(ip_address)
        
        # Check for impossible travel
        if user_id and self.detect_impossible_travel(user_id, ip_address):
            self.trigger_alert('impossible_travel', {
                'user_id': user_id,
                'ip_address': ip_address
            })
            self.require_mfa(user_id)
    
    def audit_log(self, event_type: str, details: dict):
        """Create tamper-proof audit log entry"""
        entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'details': details,
            'correlation_id': self.get_correlation_id(),
            'hash_chain': None
        }
        
        # Add hash chain for tamper detection
        previous_hash = self.get_last_log_hash()
        entry_string = json.dumps(entry, sort_keys=True)
        entry['hash_chain'] = hashlib.sha256(
            f"{previous_hash}{entry_string}".encode()
        ).hexdigest()
        
        # Store in append-only log
        self.append_to_audit_log(entry)
        
        # Real-time streaming to SIEM
        self.stream_to_siem(entry)
```

### 8. Network Security Configuration

```yaml
# Network segmentation
networks:
  dmz:
    subnet: 10.0.1.0/24
    components:
      - load_balancer
      - waf
    
  application:
    subnet: 10.0.2.0/24
    components:
      - api_gateway
      - auth_engine
    
  data:
    subnet: 10.0.3.0/24
    components:
      - postgresql
      - redis
    
  management:
    subnet: 10.0.4.0/24
    components:
      - monitoring
      - logging

# Firewall rules
firewall_rules:
  - name: allow_https_from_internet
    source: 0.0.0.0/0
    destination: dmz
    port: 443
    protocol: tcp
    action: allow
    
  - name: allow_app_to_data
    source: application
    destination: data
    ports: [5432, 6379]
    protocol: tcp
    action: allow
    
  - name: deny_all_else
    source: any
    destination: any
    action: deny
```

## Security Implementation Checklist

### Authentication & Authorization
- [ ] WebID verification with certificate validation
- [ ] DPoP implementation with proof validation
- [ ] Session management with secure cookies
- [ ] RBAC with granular permissions
- [ ] OAuth scope enforcement
- [ ] Consent tracking and management

### Cryptography
- [ ] TLS 1.3 minimum for all connections
- [ ] RS256/ES256 for JWT signing
- [ ] AES-256-GCM for data encryption
- [ ] Secure random generation
- [ ] Key rotation automation
- [ ] HSM/KMS integration

### Input/Output Security
- [ ] Input validation on all endpoints
- [ ] Output encoding for XSS prevention
- [ ] SQL injection prevention
- [ ] CSRF token validation
- [ ] File upload restrictions
- [ ] Response filtering

### Infrastructure Security
- [ ] Network segmentation
- [ ] Firewall configuration
- [ ] DDoS protection
- [ ] WAF deployment
- [ ] IDS/IPS setup
- [ ] Secure DNS configuration

### Monitoring & Response
- [ ] Comprehensive audit logging
- [ ] Real-time threat detection
- [ ] Automated alert system
- [ ] Incident response procedures
- [ ] Forensics capability
- [ ] Regular security assessments

## Security Headers Configuration

```python
SECURITY_HEADERS = {
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'",
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
    'Cache-Control': 'no-store, no-cache, must-revalidate, private',
    'Pragma': 'no-cache',
    'Expires': '0'
}
```

## Compliance & Standards

### Standards Compliance
- **OAuth 2.0**: RFC 6749, RFC 8252 (Security BCP)
- **OIDC**: OpenID Connect Core 1.0
- **DPoP**: RFC 9449
- **JOSE**: RFC 7515 (JWS), RFC 7516 (JWE)
- **TLS**: RFC 8446 (TLS 1.3)

### Regulatory Compliance
- **GDPR**: Data protection, privacy by design
- **CCPA**: California privacy rights
- **SOC 2**: Security, availability, confidentiality
- **ISO 27001**: Information security management
- **NIST**: Cybersecurity framework

## Security Metrics & KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| Mean Time to Detect (MTTD) | < 5 minutes | Security event to alert |
| Mean Time to Respond (MTTR) | < 30 minutes | Alert to containment |
| Failed Auth Rate | < 1% | Failed/Total attempts |
| Token Validation Time | < 10ms | Average validation latency |
| Security Incident Rate | < 1/month | Confirmed incidents |
| Vulnerability Scan Pass Rate | > 95% | Passed/Total checks |
| Patch Compliance | 100% critical in 24h | Patches applied on time |
| Security Training Completion | 100% | Team members trained |

## Conclusion

This security architecture provides comprehensive protection for the SolidAuth gateway through multiple layers of security controls, continuous monitoring, and incident response capabilities. Regular reviews and updates ensure the architecture evolves with emerging threats and compliance requirements.