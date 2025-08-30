# SolidAuth Gateway API Specification

## Overview

This document defines the REST API for the SolidAuth Gateway, providing Auth0-like authentication services using Solid-OIDC protocol.

**Base URL**: `https://gateway.solidauth.com/api/v1`  
**API Version**: 1.0.0  
**Authentication**: Bearer tokens or API keys depending on endpoint

## Authentication Endpoints

### 1. Initiate Authorization

Starts the OAuth 2.0 + PKCE authorization flow.

**Endpoint**: `GET /authorize`

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| client_id | string | Yes | Application client ID |
| redirect_uri | string | Yes | Callback URL (must be registered) |
| response_type | string | Yes | Must be "code" |
| scope | string | No | Space-separated scopes (default: "openid profile") |
| state | string | Yes | CSRF protection state |
| code_challenge | string | Yes | PKCE code challenge |
| code_challenge_method | string | Yes | Must be "S256" |

**Response**:
- **302 Found**: Redirects to `/login` with session cookie

**Example**:
```http
GET /api/v1/authorize?client_id=abc123&redirect_uri=https://app.example.com/callback&response_type=code&state=xyz789&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256

< HTTP/1.1 302 Found
< Location: /login?session=abc123
< Set-Cookie: solidauth_session=abc123; Path=/; Secure; HttpOnly; SameSite=Lax
```

### 2. Login with WebID

Processes WebID and initiates Solid-OIDC flow with the user's provider.

**Endpoint**: `POST /login`

**Request Body**:
```json
{
  "webid": "https://user.solidcommunity.net/profile/card#me",
  "session_id": "abc123"
}
```

**Response**:
- **302 Found**: Redirects to Solid provider authorization
- **400 Bad Request**: Invalid WebID format
- **404 Not Found**: WebID document not accessible
- **422 Unprocessable Entity**: No OIDC issuer found in WebID

**Example**:
```http
POST /api/v1/login
Content-Type: application/json

{
  "webid": "https://alice.solidweb.org/profile/card#me"
}

< HTTP/1.1 302 Found
< Location: https://solidweb.org/authorize?client_id=...
```

### 3. Handle Provider Callback

Processes the authorization code from the Solid provider.

**Endpoint**: `GET /callback`

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| code | string | Yes | Authorization code from provider |
| state | string | Yes | State parameter for CSRF protection |
| error | string | No | Error code if authorization failed |
| error_description | string | No | Human-readable error description |

**Response**:
- **302 Found**: Redirects to application with authorization code
- **400 Bad Request**: Invalid state or missing parameters
- **401 Unauthorized**: Authorization denied by user

### 4. Exchange Code for Tokens

Exchanges authorization code for access and refresh tokens.

**Endpoint**: `POST /token`

**Request Body**:
```json
{
  "grant_type": "authorization_code",
  "code": "abc123xyz",
  "client_id": "your-client-id",
  "client_secret": "your-client-secret",
  "code_verifier": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk",
  "redirect_uri": "https://app.example.com/callback"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJSUzI1NiIs...",
  "scope": "openid profile email"
}
```

**Status Codes**:
- **200 OK**: Tokens generated successfully
- **400 Bad Request**: Invalid grant type or parameters
- **401 Unauthorized**: Invalid client credentials
- **403 Forbidden**: Invalid authorization code

### 5. Refresh Access Token

Uses refresh token to obtain new access token.

**Endpoint**: `POST /token/refresh`

**Request Headers**:
```
Authorization: Bearer {refresh_token}
```

**Request Body**:
```json
{
  "grant_type": "refresh_token",
  "refresh_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJSUzI1NiIs...",
  "scope": "openid profile email"
}
```

### 6. Get User Information

Returns authenticated user's profile information.

**Endpoint**: `GET /userinfo`

**Request Headers**:
```
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "sub": "https://alice.solidweb.org/profile/card#me",
  "name": "Alice Smith",
  "preferred_username": "alice",
  "email": "alice@example.com",
  "email_verified": true,
  "picture": "https://alice.solidweb.org/profile/avatar.jpg",
  "webid": "https://alice.solidweb.org/profile/card#me",
  "solid_provider": "https://solidweb.org",
  "updated_at": 1609459200
}
```

**Status Codes**:
- **200 OK**: User information returned
- **401 Unauthorized**: Invalid or expired token

### 7. Logout

Terminates user session and optionally logs out from Solid provider.

**Endpoint**: `POST /logout`

**Request Headers**:
```
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "logout_provider": true,
  "redirect_uri": "https://app.example.com/logged-out"
}
```

**Response**:
```json
{
  "status": "logged_out",
  "redirect_uri": "https://app.example.com/logged-out"
}
```

## Application Management Endpoints

### 8. Register Application

Creates a new application registration.

**Endpoint**: `POST /apps`

**Request Headers**:
```
X-API-Key: {developer_api_key}
```

**Request Body**:
```json
{
  "name": "My Solid App",
  "description": "A decentralized social platform",
  "website": "https://myapp.example.com",
  "redirect_uris": [
    "https://myapp.example.com/callback",
    "https://localhost:3000/callback"
  ],
  "logo_uri": "https://myapp.example.com/logo.png",
  "contacts": ["admin@myapp.example.com"],
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"]
}
```

**Response**:
```json
{
  "client_id": "abc123xyz789",
  "client_secret": "secret_abc123xyz789_secret",
  "client_id_issued_at": 1609459200,
  "client_secret_expires_at": 0,
  "registration_access_token": "reg_token_abc123",
  "registration_client_uri": "/api/v1/apps/abc123xyz789",
  "application_type": "web",
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "redirect_uris": [
    "https://myapp.example.com/callback",
    "https://localhost:3000/callback"
  ]
}
```

**Status Codes**:
- **201 Created**: Application registered successfully
- **400 Bad Request**: Invalid parameters
- **401 Unauthorized**: Invalid API key
- **409 Conflict**: Application name already exists

### 9. Get Application Details

Retrieves application configuration.

**Endpoint**: `GET /apps/{client_id}`

**Request Headers**:
```
Authorization: Bearer {registration_access_token}
```

**Response**:
```json
{
  "client_id": "abc123xyz789",
  "name": "My Solid App",
  "description": "A decentralized social platform",
  "website": "https://myapp.example.com",
  "redirect_uris": [
    "https://myapp.example.com/callback"
  ],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "active": true,
  "stats": {
    "total_users": 1234,
    "active_sessions": 56,
    "requests_today": 7890
  }
}
```

### 10. Update Application

Updates application configuration.

**Endpoint**: `PUT /apps/{client_id}`

**Request Headers**:
```
Authorization: Bearer {registration_access_token}
```

**Request Body**:
```json
{
  "name": "My Updated Solid App",
  "description": "An improved decentralized platform",
  "redirect_uris": [
    "https://myapp.example.com/callback",
    "https://myapp.example.com/auth/callback"
  ],
  "website": "https://myapp.example.com"
}
```

**Response**:
```json
{
  "client_id": "abc123xyz789",
  "updated_at": "2024-01-02T00:00:00Z",
  "message": "Application updated successfully"
}
```

### 11. Delete Application

Removes application registration.

**Endpoint**: `DELETE /apps/{client_id}`

**Request Headers**:
```
Authorization: Bearer {registration_access_token}
```

**Response**:
```json
{
  "message": "Application deleted successfully",
  "deleted_at": "2024-01-02T00:00:00Z"
}
```

### 12. Rotate Client Secret

Generates new client secret for application.

**Endpoint**: `POST /apps/{client_id}/rotate-secret`

**Request Headers**:
```
Authorization: Bearer {registration_access_token}
```

**Response**:
```json
{
  "client_id": "abc123xyz789",
  "client_secret": "new_secret_xyz789abc123_secret",
  "client_secret_expires_at": 0,
  "rotated_at": "2024-01-02T00:00:00Z"
}
```

## Resource Proxy Endpoints

### 13. Access Solid Pod Resource

Proxies authenticated requests to Solid Pods.

**Endpoint**: `POST /proxy/resource`

**Request Headers**:
```
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "method": "GET",
  "url": "https://alice.solidweb.org/private/notes.ttl",
  "headers": {
    "Accept": "text/turtle"
  }
}
```

**Response**:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "text/turtle",
    "WAC-Allow": "user=\"read write\""
  },
  "body": "@prefix : <#>.\n@prefix notes: <notes#>.\n..."
}
```

## Admin Endpoints

### 14. Get System Health

Returns gateway health status.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 3600,
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 15. Get Readiness Status

Checks if service is ready to handle requests.

**Endpoint**: `GET /health/ready`

**Response**:
```json
{
  "ready": true,
  "checks": {
    "database": "connected",
    "redis": "connected",
    "providers": "reachable"
  }
}
```

### 16. Get Metrics

Returns service metrics (Prometheus format).

**Endpoint**: `GET /metrics`

**Response**:
```
# HELP solidauth_requests_total Total number of requests
# TYPE solidauth_requests_total counter
solidauth_requests_total{method="GET",endpoint="/userinfo",status="200"} 1234

# HELP solidauth_auth_duration_seconds Authentication flow duration
# TYPE solidauth_auth_duration_seconds histogram
solidauth_auth_duration_seconds_bucket{le="0.5"} 123
solidauth_auth_duration_seconds_bucket{le="1.0"} 456
```

## Error Responses

All errors follow a consistent format:

```json
{
  "error": "invalid_request",
  "error_description": "The request is missing a required parameter",
  "error_uri": "https://docs.solidauth.com/errors/invalid_request",
  "trace_id": "abc123xyz789"
}
```

### Standard Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| invalid_request | Missing or invalid parameters | 400 |
| unauthorized | Invalid credentials or token | 401 |
| forbidden | Insufficient permissions | 403 |
| not_found | Resource not found | 404 |
| method_not_allowed | HTTP method not supported | 405 |
| conflict | Resource already exists | 409 |
| rate_limited | Too many requests | 429 |
| internal_error | Server error | 500 |
| provider_error | Solid provider error | 502 |
| service_unavailable | Service temporarily unavailable | 503 |

## Rate Limiting

All endpoints are rate limited:

- **Authentication endpoints**: 10 requests per minute per IP
- **Token endpoints**: 30 requests per minute per client
- **User info endpoint**: 60 requests per minute per user
- **Application management**: 10 requests per minute per API key
- **Resource proxy**: 100 requests per minute per user

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1609459200
```

## Pagination

List endpoints support pagination:

**Query Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number |
| per_page | integer | 20 | Items per page (max: 100) |
| sort | string | created_at | Sort field |
| order | string | desc | Sort order (asc/desc) |

**Response Headers**:
```
X-Total-Count: 150
X-Page: 1
X-Per-Page: 20
Link: </api/v1/apps?page=2>; rel="next", </api/v1/apps?page=8>; rel="last"
```

## Webhooks

Applications can register webhooks for events:

### Event Types

| Event | Description | Payload |
|-------|-------------|---------|
| auth.login | User logged in | User profile, timestamp |
| auth.logout | User logged out | User ID, timestamp |
| auth.refresh | Token refreshed | User ID, timestamp |
| auth.failed | Authentication failed | Error, timestamp |
| app.updated | App config changed | Changes, timestamp |

### Webhook Registration

**Endpoint**: `POST /apps/{client_id}/webhooks`

**Request Body**:
```json
{
  "url": "https://myapp.example.com/webhooks",
  "events": ["auth.login", "auth.logout"],
  "secret": "webhook_secret_key"
}
```

## SDK Integration Examples

### JavaScript/TypeScript

```typescript
import { SolidAuth } from '@solidauth/sdk';

const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'your-client-id',
  redirectUri: window.location.origin + '/callback'
});

// Login
await auth.login();

// Get access token
const token = await auth.getAccessToken();

// Make authenticated request
const response = await fetch('https://api.example.com/data', {
  headers: {
    Authorization: `Bearer ${token}`
  }
});
```

### Python (Future)

```python
from solidauth import SolidAuth

auth = SolidAuth(
    domain='gateway.solidauth.com',
    client_id='your-client-id',
    client_secret='your-client-secret'
)

# Get access token
token = auth.get_access_token()

# Make authenticated request
response = requests.get(
    'https://api.example.com/data',
    headers={'Authorization': f'Bearer {token}'}
)
```

## Security Considerations

1. **Always use HTTPS** in production
2. **Validate redirect URIs** against registered values
3. **Implement PKCE** for all public clients
4. **Use secure session cookies** (HttpOnly, Secure, SameSite)
5. **Rotate secrets** regularly
6. **Monitor for anomalies** in authentication patterns
7. **Implement rate limiting** on all endpoints
8. **Log security events** for audit trails

## Versioning

The API uses URL versioning:
- Current version: `/api/v1`
- Future versions will be available at `/api/v2`, etc.
- Deprecation notices provided 6 months in advance
- Sunset period of 12 months for old versions

## Support

- Documentation: https://docs.solidauth.com
- GitHub Issues: https://github.com/solidauth/gateway/issues
- Email: support@solidauth.com