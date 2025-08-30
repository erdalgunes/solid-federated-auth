# SolidAuth Gateway API Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Authentication](#authentication)
4. [API Reference](#api-reference)
5. [SDK Usage](#sdk-usage)
6. [Error Handling](#error-handling)
7. [Rate Limiting](#rate-limiting)
8. [Security](#security)
9. [Webhooks](#webhooks)
10. [Examples](#examples)

## Introduction

SolidAuth Gateway provides a decentralized authentication service that gives developers an Auth0-like experience while leveraging the Solid-OIDC protocol. This enables applications to authenticate users through their Solid Pods without storing credentials or personal data.

### Key Features

- **Decentralized Identity**: Users control their identity through WebIDs
- **No Vendor Lock-in**: Works with any Solid-OIDC provider
- **Developer Friendly**: Auth0-like APIs and SDKs
- **Privacy First**: No user data stored on gateway
- **Standards Compliant**: Full OAuth 2.0 + OIDC + DPoP support

### Base URL

```
Production: https://gateway.solidauth.com/api/v1
Staging:    https://staging.solidauth.com/api/v1
Local:      http://localhost:8000/api/v1
```

## Getting Started

### 1. Register Your Application

First, register your application to obtain credentials:

```bash
curl -X POST https://gateway.solidauth.com/api/v1/apps \
  -H "X-API-Key: YOUR_DEVELOPER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Solid App",
    "redirect_uris": ["https://myapp.com/callback"],
    "website": "https://myapp.com"
  }'
```

Response:
```json
{
  "client_id": "abc123xyz789",
  "client_secret": "secret_abc123xyz789_secret",
  "registration_access_token": "reg_token_abc123"
}
```

### 2. Install the SDK

```bash
npm install @solidauth/sdk
```

### 3. Initialize Authentication

```javascript
import { SolidAuth } from '@solidauth/sdk';

const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'abc123xyz789',
  redirectUri: 'https://myapp.com/callback'
});
```

### 4. Implement Login

```javascript
// Trigger login
await auth.login();

// Handle callback
const result = await auth.handleRedirectCallback();
if (result.isAuthenticated) {
  const user = await auth.getUser();
  console.log('Welcome:', user.name);
}
```

## Authentication

### OAuth 2.0 + PKCE Flow

SolidAuth implements the OAuth 2.0 authorization code flow with PKCE (Proof Key for Code Exchange) for enhanced security.

#### Step 1: Generate PKCE Parameters

```javascript
// SDK handles this automatically
const codeVerifier = generateRandomString(128);
const codeChallenge = sha256(codeVerifier);
```

#### Step 2: Redirect to Authorization

```javascript
const params = new URLSearchParams({
  client_id: 'abc123xyz789',
  redirect_uri: 'https://myapp.com/callback',
  response_type: 'code',
  scope: 'openid profile email',
  state: generateRandomString(32),
  code_challenge: codeChallenge,
  code_challenge_method: 'S256'
});

window.location.href = `https://gateway.solidauth.com/api/v1/authorize?${params}`;
```

#### Step 3: User Enters WebID

The gateway presents a login form where users enter their WebID:

```
https://alice.solidcommunity.net/profile/card#me
```

#### Step 4: Provider Authentication

Users are redirected to their Solid provider for authentication.

#### Step 5: Exchange Code for Tokens

```javascript
const response = await fetch('https://gateway.solidauth.com/api/v1/token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    grant_type: 'authorization_code',
    code: authorizationCode,
    client_id: 'abc123xyz789',
    client_secret: 'secret_abc123xyz789_secret',
    code_verifier: codeVerifier,
    redirect_uri: 'https://myapp.com/callback'
  })
});

const tokens = await response.json();
// { access_token, refresh_token, expires_in, ... }
```

### DPoP (Demonstrating Proof-of-Possession)

For enhanced security, SolidAuth supports DPoP-bound access tokens:

```javascript
// Generate key pair
const { publicKey, privateKey } = await generateKeyPair('RS256');

// Create DPoP proof
const dpopProof = await createDPoPProof(privateKey, {
  htm: 'GET',
  htu: 'https://pod.example/resource',
  ath: sha256(accessToken)
});

// Use with requests
fetch('https://pod.example/resource', {
  headers: {
    'Authorization': `DPoP ${accessToken}`,
    'DPoP': dpopProof
  }
});
```

## API Reference

### Authentication Endpoints

#### `GET /authorize`

Initiates the OAuth 2.0 authorization flow.

**Parameters:**
- `client_id` (required): Your application's client ID
- `redirect_uri` (required): Registered callback URL
- `response_type` (required): Must be "code"
- `scope` (optional): Requested permissions (default: "openid profile")
- `state` (required): CSRF protection token
- `code_challenge` (required): PKCE challenge
- `code_challenge_method` (required): Must be "S256"

#### `POST /login`

Processes WebID and redirects to Solid provider.

**Request:**
```json
{
  "webid": "https://alice.solidcommunity.net/profile/card#me",
  "session_id": "abc123"
}
```

#### `POST /token`

Exchanges authorization code for tokens.

**Request:**
```json
{
  "grant_type": "authorization_code",
  "code": "auth_code_here",
  "client_id": "abc123xyz789",
  "client_secret": "secret",
  "code_verifier": "verifier",
  "redirect_uri": "https://myapp.com/callback"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJhbGciOiJSUzI1NiIs...",
  "scope": "openid profile email"
}
```

#### `POST /token/refresh`

Refreshes an expired access token.

**Request:**
```json
{
  "grant_type": "refresh_token",
  "refresh_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

#### `GET /userinfo`

Returns authenticated user's profile.

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "sub": "https://alice.solidweb.org/profile/card#me",
  "name": "Alice Smith",
  "email": "alice@example.com",
  "webid": "https://alice.solidweb.org/profile/card#me",
  "solid_provider": "https://solidweb.org"
}
```

#### `POST /logout`

Terminates the user session.

**Request:**
```json
{
  "logout_provider": true,
  "redirect_uri": "https://myapp.com/logged-out"
}
```

### Application Management

#### `POST /apps`

Registers a new application.

**Headers:**
```
X-API-Key: {developer_api_key}
```

**Request:**
```json
{
  "name": "My Solid App",
  "description": "A decentralized social platform",
  "website": "https://myapp.com",
  "redirect_uris": [
    "https://myapp.com/callback",
    "https://localhost:3000/callback"
  ]
}
```

#### `GET /apps/{client_id}`

Retrieves application details.

#### `PUT /apps/{client_id}`

Updates application configuration.

#### `DELETE /apps/{client_id}`

Removes application registration.

#### `POST /apps/{client_id}/rotate-secret`

Generates a new client secret.

### Resource Proxy

#### `POST /proxy/resource`

Proxies authenticated requests to Solid Pods.

**Request:**
```json
{
  "method": "GET",
  "url": "https://alice.solidweb.org/private/notes.ttl",
  "headers": {
    "Accept": "text/turtle"
  }
}
```

### Health Endpoints

#### `GET /health`

Returns system health status.

#### `GET /health/ready`

Checks service readiness.

#### `GET /metrics`

Returns Prometheus metrics.

## SDK Usage

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

// Get user
const user = await auth.getUser();

// Make authenticated request
const token = await auth.getAccessToken();
const response = await fetch('/api/data', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// Logout
await auth.logout();
```

### React

```jsx
import { SolidAuthProvider, useSolidAuth } from '@solidauth/react';

// Wrap your app
function App() {
  return (
    <SolidAuthProvider
      domain="gateway.solidauth.com"
      clientId="your-client-id"
      redirectUri={window.location.origin}
    >
      <YourApp />
    </SolidAuthProvider>
  );
}

// Use in components
function LoginButton() {
  const { isAuthenticated, login, logout, user } = useSolidAuth();
  
  if (isAuthenticated) {
    return (
      <div>
        <span>Welcome, {user.name}</span>
        <button onClick={logout}>Logout</button>
      </div>
    );
  }
  
  return <button onClick={login}>Login with Solid</button>;
}
```

### Vue

```vue
<template>
  <div>
    <button v-if="!isAuthenticated" @click="login">Login</button>
    <div v-else>
      <span>Welcome, {{ user.name }}</span>
      <button @click="logout">Logout</button>
    </div>
  </div>
</template>

<script>
import { useSolidAuth } from '@solidauth/vue';

export default {
  setup() {
    const { isAuthenticated, user, login, logout } = useSolidAuth();
    return { isAuthenticated, user, login, logout };
  }
};
</script>
```

## Error Handling

### Error Response Format

All errors follow a consistent format:

```json
{
  "error": "invalid_request",
  "error_description": "The request is missing a required parameter",
  "error_uri": "https://docs.solidauth.com/errors/invalid_request",
  "trace_id": "abc123xyz789"
}
```

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `invalid_request` | Missing or invalid parameters | 400 |
| `unauthorized` | Invalid credentials or token | 401 |
| `forbidden` | Insufficient permissions | 403 |
| `not_found` | Resource not found | 404 |
| `method_not_allowed` | HTTP method not supported | 405 |
| `conflict` | Resource already exists | 409 |
| `rate_limited` | Too many requests | 429 |
| `internal_error` | Server error | 500 |
| `provider_error` | Solid provider error | 502 |
| `service_unavailable` | Service temporarily unavailable | 503 |

### Handling Errors in SDK

```javascript
try {
  await auth.login();
} catch (error) {
  switch (error.code) {
    case 'login_required':
      // User needs to log in
      break;
    case 'consent_required':
      // User needs to provide consent
      break;
    case 'network_error':
      // Network issue, retry
      break;
    default:
      console.error('Auth error:', error);
  }
}
```

## Rate Limiting

All endpoints are rate limited to prevent abuse:

| Endpoint Type | Limit | Window |
|--------------|-------|--------|
| Authentication | 10 requests | per minute per IP |
| Token operations | 30 requests | per minute per client |
| User info | 60 requests | per minute per user |
| Application management | 10 requests | per minute per API key |
| Resource proxy | 100 requests | per minute per user |

### Rate Limit Headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1609459200
```

### Handling Rate Limits

```javascript
// SDK automatically handles rate limits with exponential backoff
const auth = new SolidAuth({
  // ... config
  retryConfig: {
    retries: 3,
    retryDelay: 1000,
    retryOn: [429]
  }
});
```

## Security

### Best Practices

1. **Always use HTTPS** in production
2. **Implement PKCE** for all public clients
3. **Validate redirect URIs** against registered values
4. **Use secure session cookies** (HttpOnly, Secure, SameSite)
5. **Rotate secrets regularly**
6. **Monitor for anomalies** in authentication patterns
7. **Implement rate limiting** on your application
8. **Log security events** for audit trails

### Content Security Policy

```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' https://gateway.solidauth.com;
  connect-src 'self' https://gateway.solidauth.com https://*.solidcommunity.net;
  frame-src https://gateway.solidauth.com;
">
```

### CORS Configuration

```javascript
// Allowed origins
const allowedOrigins = [
  'https://myapp.com',
  'https://localhost:3000'
];

// SDK handles CORS automatically
```

## Webhooks

### Registering Webhooks

```bash
curl -X POST https://gateway.solidauth.com/api/v1/apps/{client_id}/webhooks \
  -H "Authorization: Bearer {registration_access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://myapp.com/webhooks",
    "events": ["auth.login", "auth.logout"],
    "secret": "webhook_secret_key"
  }'
```

### Event Types

| Event | Description | Payload |
|-------|-------------|---------|
| `auth.login` | User logged in | User profile, timestamp |
| `auth.logout` | User logged out | User ID, timestamp |
| `auth.refresh` | Token refreshed | User ID, timestamp |
| `auth.failed` | Authentication failed | Error, timestamp |
| `app.updated` | App config changed | Changes, timestamp |

### Verifying Webhook Signatures

```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  
  return hash === signature;
}

// In your webhook handler
app.post('/webhooks', (req, res) => {
  const signature = req.headers['x-solidauth-signature'];
  
  if (!verifyWebhook(req.body, signature, WEBHOOK_SECRET)) {
    return res.status(401).send('Invalid signature');
  }
  
  // Process webhook
  switch (req.body.event) {
    case 'auth.login':
      console.log('User logged in:', req.body.user);
      break;
  }
  
  res.status(200).send('OK');
});
```

## Examples

### Complete Authentication Flow

```javascript
// 1. Initialize
const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'abc123xyz789',
  redirectUri: 'https://myapp.com/callback'
});

// 2. Check if already authenticated
if (auth.isAuthenticated()) {
  const user = await auth.getUser();
  console.log('Already logged in as:', user.name);
} else {
  // 3. Trigger login
  await auth.login();
}

// 4. Handle callback (on /callback page)
try {
  const result = await auth.handleRedirectCallback();
  if (result.isAuthenticated) {
    // 5. Get user info
    const user = await auth.getUser();
    console.log('Logged in as:', user.name);
    
    // 6. Make authenticated requests
    const token = await auth.getAccessToken();
    const response = await fetch('/api/protected', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
  }
} catch (error) {
  console.error('Authentication failed:', error);
}

// 7. Logout when needed
await auth.logout();
```

### Accessing Solid Pod Resources

```javascript
// Using the SDK's authenticated fetch
const response = await auth.fetch('https://pod.example/private/profile.ttl', {
  method: 'GET',
  headers: {
    'Accept': 'text/turtle'
  }
});

const data = await response.text();
console.log('Pod data:', data);

// Or manually with tokens
const token = await auth.getAccessToken();
const dpopProof = await auth.createDPoPProof('GET', 'https://pod.example/resource');

const response = await fetch('https://pod.example/resource', {
  headers: {
    'Authorization': `DPoP ${token}`,
    'DPoP': dpopProof
  }
});
```

### Silent Authentication

```javascript
// Check for existing session without redirect
const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'abc123xyz789',
  redirectUri: 'https://myapp.com/callback'
});

try {
  const result = await auth.checkSession();
  if (result.isAuthenticated) {
    console.log('User already has active session');
    const user = await auth.getUser();
    // Continue with authenticated flow
  } else {
    // Show login button
  }
} catch (error) {
  // No active session, show login
}
```

### Multi-Provider Support

```javascript
// Let users choose their provider
const providers = [
  { name: 'Inrupt', url: 'https://broker.pod.inrupt.com' },
  { name: 'Solid Community', url: 'https://solidcommunity.net' },
  { name: 'Solid Web', url: 'https://solidweb.org' }
];

// Login with specific provider
await auth.login({
  provider: 'https://broker.pod.inrupt.com'
});

// Or with WebID (provider auto-detected)
await auth.login({
  webId: 'https://alice.solidcommunity.net/profile/card#me'
});
```

## Troubleshooting

### Common Issues

#### "Invalid redirect_uri"
Ensure your callback URL is registered in your application settings.

#### "Token expired"
The SDK should automatically refresh tokens. If not, manually call:
```javascript
await auth.refreshToken();
```

#### "CORS error"
Add your domain to the application's allowed origins in settings.

#### "Provider unavailable"
The Solid provider may be down. The gateway will attempt to use cached configuration if available.

### Debug Mode

Enable debug logging:

```javascript
const auth = new SolidAuth({
  // ... config
  debug: true
});

// Or enable globally
localStorage.setItem('solidauth:debug', 'true');
```

### Support

- **Documentation**: https://docs.solidauth.com
- **GitHub Issues**: https://github.com/erdalgunes/solid-federated-auth/issues
- **Email**: support@solidauth.com
- **Discord**: https://discord.gg/solidauth

## Migration Guides

### From Auth0

```javascript
// Before (Auth0)
const auth0 = new Auth0Client({
  domain: 'tenant.auth0.com',
  client_id: 'xxx',
  redirect_uri: window.location.origin
});

// After (SolidAuth)
const solidAuth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'xxx',  // Note: camelCase
  redirectUri: window.location.origin
});

// Most method names remain the same:
// auth0.loginWithRedirect() → solidAuth.login()
// auth0.getUser() → solidAuth.getUser()
// auth0.getTokenSilently() → solidAuth.getAccessToken()
// auth0.logout() → solidAuth.logout()
```

### From Inrupt SDK

```javascript
// Before (Inrupt)
import { Session } from '@inrupt/solid-client-authn-browser';
const session = new Session();
await session.login({
  oidcIssuer: 'https://broker.pod.inrupt.com',
  redirectUrl: window.location.href
});

// After (SolidAuth)
const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'xxx',
  redirectUri: window.location.href
});
await auth.login({
  provider: 'https://broker.pod.inrupt.com'
});
```

## Changelog

### v1.0.0 (2024-01-30)
- Initial release
- OAuth 2.0 + PKCE support
- Solid-OIDC authentication
- DPoP token support
- JavaScript SDK
- Application management API

### Roadmap
- v1.1: React, Vue, Angular integrations
- v1.2: WebAuthn support
- v1.3: Offline mode
- v2.0: Real-time subscriptions