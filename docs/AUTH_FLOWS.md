# Authentication Flow Diagrams

## 1. Complete Authentication Flow with DPoP

```mermaid
sequenceDiagram
    participant U as User
    participant B as Browser
    participant A as App (Client)
    participant SDK
    participant GW as SolidAuth Gateway
    participant R as Redis Cache
    participant DB as PostgreSQL
    participant SP as Solid Provider
    participant Pod as User's Pod

    Note over U,Pod: Initial Authentication Request
    
    U->>B: Access Application
    B->>A: GET /
    A->>SDK: Check auth status
    SDK->>B: Not authenticated
    A->>B: Show login button
    
    U->>B: Click "Login with Solid"
    B->>A: Trigger login
    A->>SDK: solidAuth.login()
    
    Note over SDK,GW: OAuth 2.0 + PKCE Flow Initiation
    
    SDK->>SDK: Generate code_verifier
    SDK->>SDK: Calculate code_challenge
    SDK->>GW: GET /api/v1/authorize
    Note right of SDK: client_id, redirect_uri,<br/>code_challenge, state
    
    GW->>DB: Validate client_id
    DB-->>GW: Client config
    GW->>GW: Generate session_id
    GW->>R: Store auth session
    Note right of R: session_id, state,<br/>code_challenge, client_id
    
    GW-->>B: Redirect to /login
    Note right of GW: Set session cookie
    
    Note over B,SP: WebID Discovery Phase
    
    B->>GW: GET /login
    GW-->>B: Show WebID input form
    U->>B: Enter WebID
    B->>GW: POST /login
    Note right of B: webid, session_id
    
    GW->>GW: Parse WebID URL
    GW->>Pod: GET {webid}
    Pod-->>GW: WebID Document
    Note right of Pod: Contains issuer URL
    
    GW->>GW: Extract OIDC issuer
    GW->>SP: GET /.well-known/openid-configuration
    SP-->>GW: OIDC Discovery Document
    
    Note over GW,SP: Solid-OIDC Authentication
    
    GW->>GW: Generate DPoP key pair
    GW->>R: Store DPoP keys
    Note right of R: session_id -> keys
    
    GW->>SP: GET /authorize
    Note right of GW: response_type=code,<br/>client_id=gateway,<br/>redirect_uri, scope, state
    
    SP-->>B: Redirect to SP login
    U->>B: Enter credentials
    B->>SP: POST credentials
    SP->>SP: Validate user
    SP-->>B: Authorization consent
    U->>B: Approve access
    B->>SP: POST consent
    
    SP-->>GW: Redirect with code
    Note right of SP: code, state
    
    Note over GW,SP: Token Exchange with DPoP
    
    GW->>R: Retrieve DPoP keys
    R-->>GW: Private/public keys
    
    GW->>GW: Create DPoP proof
    Note right of GW: JWT signed with private key,<br/>includes: jti, htm, htu, iat
    
    GW->>SP: POST /token
    Note right of GW: Headers: DPoP: {proof}<br/>Body: grant_type=authorization_code,<br/>code, redirect_uri
    
    SP->>SP: Validate DPoP proof
    SP->>SP: Validate code
    SP-->>GW: Tokens
    Note right of SP: access_token (DPoP-bound),<br/>id_token, refresh_token
    
    Note over GW,A: Session Establishment
    
    GW->>GW: Parse id_token
    GW->>GW: Extract user info
    GW->>GW: Generate internal session
    
    GW->>R: Store user session
    Note right of R: session_id -> {<br/>  user_info,<br/>  access_token,<br/>  refresh_token,<br/>  dpop_keys<br/>}
    
    GW->>DB: Log authentication event
    
    GW-->>B: Redirect to app callback
    Note right of GW: /callback?code={auth_code}&state={state}
    
    B->>A: GET /callback
    A->>SDK: Handle callback
    SDK->>GW: POST /api/v1/token
    Note right of SDK: code, code_verifier
    
    GW->>R: Validate auth code
    GW->>GW: Generate app tokens
    GW-->>SDK: App tokens
    Note right of GW: access_token, refresh_token,<br/>expires_in
    
    SDK->>SDK: Store tokens
    SDK-->>A: Authentication complete
    A->>SDK: getUser()
    SDK->>GW: GET /api/v1/userinfo
    GW->>R: Get session
    GW-->>SDK: User profile
    SDK-->>A: User object
    A-->>B: Show authenticated UI
```

## 2. Token Refresh Flow

```mermaid
sequenceDiagram
    participant A as App
    participant SDK
    participant GW as Gateway
    participant R as Redis
    participant SP as Solid Provider

    Note over A,SP: Token Expiration Handling
    
    A->>SDK: Make API call
    SDK->>SDK: Check token expiry
    Note right of SDK: Token expired
    
    SDK->>GW: POST /api/v1/token/refresh
    Note right of SDK: refresh_token
    
    GW->>R: Get session by refresh token
    R-->>GW: Session data with DPoP keys
    
    GW->>GW: Create new DPoP proof
    
    GW->>SP: POST /token
    Note right of GW: grant_type=refresh_token,<br/>refresh_token,<br/>DPoP header
    
    SP->>SP: Validate refresh token
    SP->>SP: Validate DPoP proof
    SP-->>GW: New tokens
    
    GW->>R: Update session
    GW->>GW: Generate new app tokens
    
    GW-->>SDK: New tokens
    SDK->>SDK: Update stored tokens
    SDK->>A: Retry API call
    A-->>SDK: Success
```

## 3. Logout Flow

```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant SDK
    participant GW as Gateway
    participant R as Redis
    participant SP as Solid Provider

    U->>A: Click Logout
    A->>SDK: solidAuth.logout()
    
    SDK->>GW: POST /api/v1/logout
    Note right of SDK: access_token
    
    GW->>R: Get session
    R-->>GW: Session data
    
    GW->>SP: POST /logout
    Note right of GW: id_token_hint
    
    SP->>SP: Terminate provider session
    SP-->>GW: Logout confirmed
    
    GW->>R: Delete session
    GW->>DB: Log logout event
    
    GW-->>SDK: Logout complete
    SDK->>SDK: Clear local tokens
    SDK-->>A: Logged out
    A-->>U: Show login screen
```

## 4. Application Registration Flow

```mermaid
sequenceDiagram
    participant D as Developer
    participant P as Portal UI
    participant GW as Gateway API
    participant DB as PostgreSQL
    participant E as Email Service

    D->>P: Access registration
    P->>P: Show registration form
    
    D->>P: Fill app details
    Note right of D: name, description,<br/>redirect_uris, website
    
    P->>GW: POST /api/v1/apps
    Note right of P: App metadata
    
    GW->>GW: Validate input
    GW->>GW: Generate client_id
    GW->>GW: Generate client_secret
    
    GW->>DB: Store app config
    DB-->>GW: App created
    
    GW->>E: Send welcome email
    Note right of GW: Contains setup instructions
    
    GW-->>P: App credentials
    P-->>D: Display credentials
    Note right of P: client_id, client_secret,<br/>setup instructions
    
    D->>D: Copy credentials
    D->>D: Integrate SDK
```

## 5. Resource Access Flow (Using DPoP)

```mermaid
sequenceDiagram
    participant A as App
    participant SDK
    participant GW as Gateway
    participant R as Redis
    participant Pod as Solid Pod

    Note over A,Pod: Accessing User's Solid Pod
    
    A->>SDK: Read pod resource
    Note right of A: resourceUrl
    
    SDK->>GW: POST /api/v1/proxy/resource
    Note right of SDK: access_token,<br/>resource_url
    
    GW->>R: Get session
    R-->>GW: DPoP keys, Solid tokens
    
    GW->>GW: Create DPoP proof
    Note right of GW: For specific resource URL
    
    GW->>Pod: GET {resource_url}
    Note right of GW: Authorization: DPoP {token}<br/>DPoP: {proof}
    
    Pod->>Pod: Validate DPoP binding
    Pod->>Pod: Check ACL permissions
    Pod-->>GW: Resource data
    
    GW-->>SDK: Resource content
    SDK-->>A: Data
```

## 6. Error Recovery Flows

### 6.1 Provider Unavailable

```mermaid
sequenceDiagram
    participant U as User
    participant GW as Gateway
    participant SP as Solid Provider
    participant R as Redis

    U->>GW: POST /login (with WebID)
    GW->>SP: GET /.well-known/openid-configuration
    SP--xGW: Timeout/Error
    
    GW->>R: Check cached provider config
    alt Config cached
        R-->>GW: Cached config
        GW->>GW: Proceed with cached config
    else No cache
        GW->>GW: Try alternate discovery
        GW->>SP: GET /oauth2/configuration
        alt Success
            SP-->>GW: Config document
            GW->>R: Cache config
        else Failed
            GW-->>U: Provider unavailable error
            Note right of GW: Suggest trying later
        end
    end
```

### 6.2 Session Expired During Flow

```mermaid
sequenceDiagram
    participant U as User
    participant B as Browser
    participant GW as Gateway
    participant R as Redis
    participant SP as Solid Provider

    Note over U,SP: Callback after session timeout
    
    SP-->>B: Redirect to callback
    B->>GW: GET /callback
    Note right of B: code, state
    
    GW->>R: Get session by state
    R-->>GW: Session not found
    
    GW->>GW: Create recovery session
    GW->>R: Store recovery state
    
    GW-->>B: Redirect to /login
    Note right of GW: With recovery flag
    
    B->>GW: GET /login?recovery=true
    GW-->>U: Show recovery message
    Note right of GW: "Session expired, please login again"
```

## 7. Multi-Provider Support Flow

```mermaid
sequenceDiagram
    participant U as User
    participant GW as Gateway
    participant SP1 as Provider 1 (Inrupt)
    participant SP2 as Provider 2 (Solidcommunity)
    participant R as Redis

    Note over U,SP2: Supporting Multiple Solid Providers
    
    U->>GW: POST /login
    Note right of U: webid=https://user.inrupt.net/profile
    
    GW->>GW: Extract provider from WebID
    GW->>R: Check provider config cache
    
    alt Provider known
        R-->>GW: Cached Inrupt config
    else Unknown provider
        GW->>SP1: Discover OIDC config
        SP1-->>GW: Config document
        GW->>R: Cache provider config
    end
    
    GW->>SP1: Initiate auth flow
    Note right of GW: Provider-specific endpoints
    
    Note over U,SP2: Different user, different provider
    
    U->>GW: POST /login
    Note right of U: webid=https://user.solidcommunity.net/profile
    
    GW->>GW: Extract provider
    GW->>R: Check provider config cache
    GW->>SP2: Discover OIDC config
    SP2-->>GW: Config document
    
    GW->>SP2: Initiate auth flow
    Note right of GW: Different provider endpoints
```

## 8. Security Token Validation Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant GW as Gateway
    participant R as Redis
    participant V as Validation Service

    Note over C,V: Every Authenticated Request
    
    C->>GW: API Request
    Note right of C: Authorization: Bearer {token}
    
    GW->>GW: Extract token
    GW->>R: Check token blacklist
    
    alt Token blacklisted
        GW-->>C: 401 Unauthorized
    else Token valid
        GW->>R: Get session by token
        alt Session exists
            R-->>GW: Session data
            GW->>V: Validate token signature
            V-->>GW: Valid
            GW->>GW: Check expiration
            alt Not expired
                GW->>GW: Process request
                GW-->>C: 200 OK
            else Expired
                GW-->>C: 401 Token Expired
            end
        else No session
            GW-->>C: 401 Invalid Token
        end
    end
```

## Flow Decision Matrix

| Scenario | Flow Type | Key Considerations |
|----------|-----------|-------------------|
| First-time user | Full authentication | WebID discovery, provider selection |
| Returning user | Session-based | Cookie validation, token refresh |
| API access | Token validation | DPoP proof generation |
| Provider down | Error recovery | Cached configs, retry logic |
| Token expired | Refresh flow | Automatic refresh, seamless UX |
| Logout | Cleanup flow | Provider logout, session cleanup |
| Multiple apps | Shared session | SSO capabilities, session linking |

## Security Checkpoints

Each flow includes the following security validations:

1. **Client Validation**: Verify client_id and redirect_uri
2. **State Parameter**: Prevent CSRF attacks
3. **PKCE**: Prevent authorization code interception
4. **DPoP Binding**: Prevent token replay attacks
5. **Session Binding**: Link sessions to specific clients
6. **Rate Limiting**: Prevent brute force attacks
7. **Input Validation**: Prevent injection attacks
8. **TLS/HTTPS**: Encrypt all communications

## Performance Optimizations

1. **Caching**: Provider configs, user sessions, token validation
2. **Connection Pooling**: Reuse HTTP connections to providers
3. **Async Operations**: Non-blocking I/O for all external calls
4. **Batch Operations**: Group related operations when possible
5. **Lazy Loading**: Load user details only when needed
6. **Token Lifecycle**: Proactive refresh before expiration