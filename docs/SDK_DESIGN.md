# JavaScript SDK Interface Design

## Overview

The SolidAuth JavaScript SDK provides a simple, Auth0-like interface for integrating Solid-OIDC authentication into web applications. Following YAGNI principles, we start with essential functionality and expand based on real usage patterns.

## Design Principles

1. **Simplicity First**: Auth0-like DX with minimal configuration
2. **Progressive Enhancement**: Basic auth works immediately, advanced features optional
3. **Type Safety**: Full TypeScript support with comprehensive types
4. **Framework Agnostic**: Works with React, Vue, Angular, or vanilla JS
5. **Secure by Default**: PKCE, secure session handling, DPoP support built-in

## Core API

### Installation

```bash
npm install @solidauth/sdk
# or
yarn add @solidauth/sdk
```

### Basic Usage

```typescript
import { SolidAuth } from '@solidauth/sdk';

// Initialize
const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'your-client-id',
  redirectUri: window.location.origin + '/callback'
});

// Login
await auth.login();

// Check authentication
if (auth.isAuthenticated()) {
  const user = await auth.getUser();
  console.log('Logged in as:', user.webid);
}

// Logout
await auth.logout();
```

## SDK Interface

### Main Class: `SolidAuth`

```typescript
class SolidAuth {
  constructor(config: SolidAuthConfig);
  
  // Core authentication methods
  login(options?: LoginOptions): Promise<void>;
  logout(options?: LogoutOptions): Promise<void>;
  handleRedirectCallback(): Promise<AuthResult>;
  
  // State methods
  isAuthenticated(): boolean;
  getUser(): Promise<User | null>;
  getAccessToken(): Promise<string | null>;
  
  // Solid-specific methods
  getWebId(): string | null;
  getSolidProvider(): string | null;
  
  // Resource access
  fetch(url: string, options?: FetchOptions): Promise<Response>;
  
  // Event handling
  on(event: AuthEvent, handler: EventHandler): void;
  off(event: AuthEvent, handler: EventHandler): void;
}
```

### Configuration Interface

```typescript
interface SolidAuthConfig {
  // Required
  domain: string;
  clientId: string;
  redirectUri: string;
  
  // Optional
  scope?: string;                    // Default: 'openid profile'
  audience?: string;                  // API identifier
  cacheLocation?: 'memory' | 'local'; // Default: 'memory'
  useRefreshTokens?: boolean;         // Default: true
  leeway?: number;                    // Clock skew in seconds
  
  // Advanced
  httpTimeoutInSeconds?: number;      // Default: 60
  cookieDomain?: string;              // For SSO across subdomains
  useCookiesForTransactions?: boolean; // Default: true
  
  // Hooks
  onRedirectCallback?: (result: AuthResult) => void;
  onAuthError?: (error: AuthError) => void;
}
```

### Login Options

```typescript
interface LoginOptions {
  // WebID or provider selection
  webId?: string;                     // Direct WebID login
  provider?: string;                  // Provider URL
  
  // UI options
  display?: 'page' | 'popup' | 'touch' | 'wap';
  prompt?: 'none' | 'login' | 'consent' | 'select_account';
  maxAge?: number;
  uiLocales?: string;
  
  // Advanced
  loginHint?: string;
  acrValues?: string;
  connection?: string;
  
  // Custom parameters
  customParams?: Record<string, string>;
}
```

### User Interface

```typescript
interface User {
  // Standard OIDC claims
  sub: string;                        // WebID
  name?: string;
  preferred_username?: string;
  email?: string;
  email_verified?: boolean;
  picture?: string;
  updated_at?: number;
  
  // Solid-specific
  webid: string;                      // Same as sub
  solid_provider: string;             // Provider URL
  pod_url?: string;                   // Primary storage
  
  // Extended profile
  [key: string]: any;                 // Additional claims
}
```

### Error Handling

```typescript
interface AuthError extends Error {
  error: string;
  error_description?: string;
  error_uri?: string;
  state?: string;
  
  // Error codes
  code: ErrorCode;
}

enum ErrorCode {
  // Auth errors
  LOGIN_REQUIRED = 'login_required',
  CONSENT_REQUIRED = 'consent_required',
  INTERACTION_REQUIRED = 'interaction_required',
  
  // Token errors
  INVALID_TOKEN = 'invalid_token',
  TOKEN_EXPIRED = 'token_expired',
  
  // Network errors
  NETWORK_ERROR = 'network_error',
  TIMEOUT = 'timeout',
  
  // Configuration errors
  INVALID_CONFIG = 'invalid_config',
  MISSING_REFRESH_TOKEN = 'missing_refresh_token'
}
```

## Framework Integrations

### React Hook

```typescript
import { useSolidAuth } from '@solidauth/react';

function LoginButton() {
  const { 
    isAuthenticated, 
    isLoading, 
    user, 
    login, 
    logout 
  } = useSolidAuth();
  
  if (isLoading) return <div>Loading...</div>;
  
  if (isAuthenticated) {
    return (
      <div>
        <span>Welcome, {user?.name}</span>
        <button onClick={() => logout()}>Logout</button>
      </div>
    );
  }
  
  return <button onClick={() => login()}>Login with Solid</button>;
}
```

### Vue Composable

```typescript
import { useSolidAuth } from '@solidauth/vue';

export default {
  setup() {
    const { isAuthenticated, user, login, logout } = useSolidAuth();
    
    return {
      isAuthenticated,
      user,
      login,
      logout
    };
  }
};
```

### Angular Service

```typescript
import { SolidAuthService } from '@solidauth/angular';

@Component({
  selector: 'app-login',
  template: `
    <button *ngIf="!auth.isAuthenticated$ | async" 
            (click)="auth.login()">
      Login
    </button>
  `
})
export class LoginComponent {
  constructor(public auth: SolidAuthService) {}
}
```

## Advanced Features

### Silent Authentication

```typescript
// Check for existing session without redirect
const result = await auth.checkSession();
if (result.isAuthenticated) {
  console.log('User already logged in');
}
```

### Token Management

```typescript
// Get token with automatic refresh
const token = await auth.getAccessToken({
  ignoreCache: false,
  minFresh: 60 // Refresh if expires in < 60 seconds
});

// Manual refresh
await auth.refreshToken();

// Token lifecycle events
auth.on('tokenRefreshed', (tokens) => {
  console.log('New access token:', tokens.access_token);
});
```

### Solid Pod Access

```typescript
// Authenticated fetch with DPoP
const response = await auth.fetch('https://pod.example/private/notes.ttl', {
  method: 'GET',
  headers: {
    'Accept': 'text/turtle'
  }
});

// Helper methods
const data = await auth.readResource('https://pod.example/profile');
await auth.writeResource('https://pod.example/notes', data);
```

### Multi-Tab Synchronization

```typescript
// Sync auth state across tabs
auth.on('authStateChanged', (state) => {
  if (state.isAuthenticated) {
    updateUI();
  }
});
```

## Security Features

### PKCE (Proof Key for Code Exchange)

Automatically handled by the SDK:

```typescript
// SDK internally generates and manages:
// - code_verifier (cryptographically random)
// - code_challenge (SHA256 hash)
// - Secure state parameter
```

### DPoP (Demonstrating Proof-of-Possession)

```typescript
// Enable DPoP for enhanced security
const auth = new SolidAuth({
  // ... other config
  useDPoP: true // Automatically creates and manages DPoP proofs
});
```

### Session Security

```typescript
// Secure session configuration
const auth = new SolidAuth({
  // ... other config
  sessionCheckExpiryOffset: 60,    // Check 60s before expiry
  useRefreshTokensFallback: false,  // Strict refresh token usage
  tokenEndpointAuthMethod: 'client_secret_post'
});
```

## Error Recovery

### Automatic Retry

```typescript
const auth = new SolidAuth({
  // ... other config
  retryConfig: {
    retries: 3,
    retryDelay: 1000,
    retryOn: [408, 429, 500, 502, 503, 504]
  }
});
```

### Error Handling

```typescript
try {
  await auth.login();
} catch (error) {
  if (error.code === ErrorCode.CONSENT_REQUIRED) {
    // Handle consent requirement
  } else if (error.code === ErrorCode.NETWORK_ERROR) {
    // Handle network issues
  }
}

// Global error handler
auth.on('error', (error) => {
  console.error('Auth error:', error);
  // Send to error tracking service
});
```

## Testing Support

### Mock Mode

```typescript
// For testing
const auth = new SolidAuth({
  // ... other config
  mock: true,
  mockUser: {
    webid: 'https://test.example/profile#me',
    name: 'Test User'
  }
});
```

### Test Utilities

```typescript
import { createMockAuth, mockTokenResponse } from '@solidauth/testing';

describe('Authentication', () => {
  it('should handle login', async () => {
    const auth = createMockAuth();
    await auth.login();
    expect(auth.isAuthenticated()).toBe(true);
  });
});
```

## Migration Guide

### From Auth0

```typescript
// Auth0
const auth0 = new Auth0Client({
  domain: 'tenant.auth0.com',
  client_id: 'xxx',
  redirect_uri: window.location.origin
});

// SolidAuth (minimal changes)
const solidAuth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'xxx',  // Note: camelCase
  redirectUri: window.location.origin
});
```

### From Inrupt SDK

```typescript
// Inrupt
import { Session } from '@inrupt/solid-client-authn-browser';
const session = new Session();
await session.login({
  oidcIssuer: 'https://broker.pod.inrupt.com',
  redirectUrl: window.location.href
});

// SolidAuth
const auth = new SolidAuth({
  domain: 'gateway.solidauth.com',
  clientId: 'xxx',
  redirectUri: window.location.href
});
await auth.login({
  provider: 'https://broker.pod.inrupt.com'
});
```

## Bundle Sizes

Keeping bundle size minimal through:

1. **Tree-shaking**: Only import what you use
2. **Code splitting**: Lazy load advanced features
3. **Minimal dependencies**: Core has zero dependencies

```javascript
// Core bundle: ~15KB gzipped
import { SolidAuth } from '@solidauth/sdk';

// With React integration: ~18KB gzipped
import { SolidAuthProvider, useSolidAuth } from '@solidauth/react';

// Full bundle with all features: ~25KB gzipped
import * as SolidAuth from '@solidauth/sdk';
```

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Polyfills needed for older browsers:
- Web Crypto API
- Promise
- Fetch
- URLSearchParams

## TypeScript Support

Full TypeScript support with:
- Strict type checking
- Comprehensive type definitions
- IDE autocomplete
- Type guards for runtime checks

```typescript
// Type guards
if (auth.isAuthenticated()) {
  const user = await auth.getUser();
  // TypeScript knows user is not null here
}

// Generic types for extended claims
interface CustomUser extends User {
  organization: string;
  role: string;
}

const user = await auth.getUser<CustomUser>();
console.log(user.organization); // Type-safe access
```

## Performance Optimizations

1. **Token caching**: Minimize network requests
2. **Lazy loading**: Load features on demand
3. **Worker support**: Offload crypto operations
4. **Request batching**: Combine multiple requests
5. **Connection pooling**: Reuse HTTP connections

## Roadmap

### v1.0 (MVP)
- [x] Core authentication flow
- [x] Token management
- [x] Basic error handling
- [x] TypeScript support

### v1.1
- [ ] React hooks
- [ ] Vue composables
- [ ] Angular service
- [ ] Improved error recovery

### v1.2
- [ ] WebAuthn support
- [ ] Biometric authentication
- [ ] Offline mode
- [ ] Service Worker integration

### v2.0
- [ ] Real-time subscriptions
- [ ] GraphQL support
- [ ] Federation management
- [ ] Advanced Pod operations

## Example Applications

### Minimal Example

```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.solidauth.com/sdk/1.0.0/solidauth.min.js"></script>
</head>
<body>
  <button id="login">Login</button>
  <div id="profile"></div>
  
  <script>
    const auth = new SolidAuth.Client({
      domain: 'gateway.solidauth.com',
      clientId: 'your-client-id',
      redirectUri: window.location.origin
    });
    
    document.getElementById('login').onclick = () => auth.login();
    
    auth.handleRedirectCallback().then(() => {
      if (auth.isAuthenticated()) {
        auth.getUser().then(user => {
          document.getElementById('profile').innerText = 
            `Logged in as: ${user.name}`;
        });
      }
    });
  </script>
</body>
</html>
```

### React SPA

```typescript
// App.tsx
import { SolidAuthProvider } from '@solidauth/react';

function App() {
  return (
    <SolidAuthProvider
      domain="gateway.solidauth.com"
      clientId="your-client-id"
      redirectUri={window.location.origin}
    >
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
        </Routes>
      </Router>
    </SolidAuthProvider>
  );
}
```

## Support Matrix

| Feature | Browser | Node.js | React Native | Electron |
|---------|---------|---------|--------------|----------|
| Core Auth | ✅ | ✅ | ✅ | ✅ |
| PKCE | ✅ | ✅ | ✅ | ✅ |
| DPoP | ✅ | ✅ | ⚠️ | ✅ |
| Silent Auth | ✅ | N/A | ❌ | ✅ |
| Popup Mode | ✅ | N/A | ❌ | ✅ |
| Service Worker | ✅ | N/A | ❌ | ✅ |

Legend: ✅ Supported | ⚠️ Partial | ❌ Not Supported | N/A Not Applicable