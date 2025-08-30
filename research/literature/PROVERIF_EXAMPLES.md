# ProVerif Example Models for OAuth/OIDC Verification

## Introduction

This document contains example ProVerif models for verifying OAuth 2.0 and OpenID Connect protocols. These models can serve as starting points for our Solid-OIDC gateway verification.

## 1. Basic OAuth 2.0 Authorization Code Flow

```proverif
(* OAuth 2.0 Authorization Code Grant - Simplified Model *)

(* Channel declarations *)
free c: channel.              (* Public channel *)
free sc: channel [private].   (* Secure channel *)

(* Type declarations *)
type nonce.
type host.
type key.

(* Cryptographic primitives *)
fun encrypt(bitstring, key): bitstring.
fun decrypt(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; decrypt(encrypt(m, k), k) = m.

fun sign(bitstring, key): bitstring.
fun verify(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; verify(sign(m, k), k) = m.

fun hash(bitstring): bitstring.

(* Constants *)
const client_id: bitstring.
const client_secret: bitstring [private].
const redirect_uri: bitstring.

(* Events for correspondence assertions *)
event clientRequests(bitstring).
event serverIssuesCode(bitstring, bitstring).
event clientReceivesCode(bitstring).
event serverIssuesToken(bitstring, bitstring).
event clientReceivesToken(bitstring).

(* Queries *)
query attacker(client_secret).

query code: bitstring; 
  event(clientReceivesCode(code)) ==> event(serverIssuesCode(client_id, code)).

query token: bitstring;
  event(clientReceivesToken(token)) ==> event(serverIssuesToken(client_id, token)).

(* Client Process *)
let client(client_id: bitstring, client_secret: bitstring, redirect_uri: bitstring) =
  (* Step 1: Authorization Request *)
  new state: nonce;
  event clientRequests(client_id);
  out(c, (client_id, redirect_uri, state));
  
  (* Step 2: Receive Authorization Code *)
  in(c, (=state, auth_code: bitstring));
  event clientReceivesCode(auth_code);
  
  (* Step 3: Token Request *)
  out(sc, (client_id, client_secret, auth_code, redirect_uri));
  
  (* Step 4: Receive Access Token *)
  in(sc, access_token: bitstring);
  event clientReceivesToken(access_token);
  0.

(* Authorization Server Process *)
let auth_server() =
  (* Step 1: Receive Authorization Request *)
  in(c, (client_id_req: bitstring, redirect_uri_req: bitstring, state_req: nonce));
  
  (* User authentication and consent (abstracted) *)
  (* Step 2: Issue Authorization Code *)
  new auth_code: nonce;
  event serverIssuesCode(client_id_req, auth_code);
  out(c, (state_req, auth_code));
  
  (* Step 3: Receive Token Request *)
  in(sc, (=client_id_req, client_secret_req: bitstring, =auth_code, =redirect_uri_req));
  
  (* Verify client credentials *)
  if client_secret_req = client_secret then
  (
    (* Step 4: Issue Access Token *)
    new access_token: nonce;
    event serverIssuesToken(client_id_req, access_token);
    out(sc, access_token)
  ).

(* Main Process *)
process
  (!client(client_id, client_secret, redirect_uri)) |
  (!auth_server())
```

## 2. OAuth 2.0 with PKCE Extension

```proverif
(* OAuth 2.0 with PKCE (Proof Key for Code Exchange) *)

free c: channel.

type nonce.
type key.

(* Hash function for code challenge *)
fun sha256(bitstring): bitstring.

(* Base64 URL encoding *)
fun base64url(bitstring): bitstring.

(* Constants *)
const client_id: bitstring.
const redirect_uri: bitstring.

(* Events *)
event clientStartsPKCE(bitstring, bitstring).
event serverVerifiesPKCE(bitstring, bitstring).
event tokenIssued(bitstring).

(* Queries *)
query verifier: bitstring, challenge: bitstring;
  event(serverVerifiesPKCE(verifier, challenge)) ==> 
  event(clientStartsPKCE(verifier, challenge)).

(* PKCE Client *)
let pkce_client() =
  (* Generate code verifier and challenge *)
  new code_verifier: nonce;
  let code_challenge = sha256(code_verifier) in
  
  event clientStartsPKCE(code_verifier, code_challenge);
  
  (* Authorization request with code challenge *)
  new state: nonce;
  out(c, (client_id, redirect_uri, state, code_challenge, "S256"));
  
  (* Receive authorization code *)
  in(c, (=state, auth_code: bitstring));
  
  (* Token request with code verifier *)
  out(c, (client_id, auth_code, redirect_uri, code_verifier));
  
  (* Receive token *)
  in(c, access_token: bitstring);
  event tokenIssued(access_token);
  0.

(* PKCE-enabled Authorization Server *)
let pkce_server() =
  (* Receive authorization request with challenge *)
  in(c, (client_id_req: bitstring, redirect_uri_req: bitstring, 
         state_req: nonce, challenge_req: bitstring, method: bitstring));
  
  (* Store challenge (simplified) *)
  new auth_code: nonce;
  out(c, (state_req, auth_code));
  
  (* Receive token request with verifier *)
  in(c, (=client_id_req, =auth_code, =redirect_uri_req, verifier_req: bitstring));
  
  (* Verify PKCE *)
  if sha256(verifier_req) = challenge_req then
  (
    event serverVerifiesPKCE(verifier_req, challenge_req);
    new access_token: nonce;
    out(c, access_token)
  ).

process
  (!pkce_client()) | (!pkce_server())
```

## 3. OpenID Connect Basic Flow

```proverif
(* OpenID Connect Authorization Code Flow *)

free c: channel.
free secure: channel [private].

type nonce.
type key.

(* JWT operations *)
fun jwt_sign(bitstring, key): bitstring.
fun jwt_verify(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; jwt_verify(jwt_sign(m, k), k) = m.

(* Asymmetric encryption *)
fun pk(key): key.
fun aenc(bitstring, key): bitstring.
fun adec(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; adec(aenc(m, pk(k)), k) = m.

(* Constants *)
const client_id: bitstring.
const client_secret: bitstring [private].
const issuer: bitstring.

(* Private keys *)
free idp_signing_key: key [private].

(* Events *)
event idTokenIssued(bitstring, bitstring).
event idTokenVerified(bitstring, bitstring).
event userAuthenticated(bitstring).

(* Queries *)
query attacker(client_secret).

query sub: bitstring, nonce_val: bitstring;
  event(idTokenVerified(sub, nonce_val)) ==> 
  event(idTokenIssued(sub, nonce_val)).

(* OpenID Connect Client (Relying Party) *)
let oidc_client() =
  (* Authorization request with nonce *)
  new nonce_val: nonce;
  new state: nonce;
  out(c, (client_id, redirect_uri, state, nonce_val, "openid profile"));
  
  (* Receive authorization code *)
  in(c, (=state, auth_code: bitstring));
  
  (* Token request *)
  out(secure, (client_id, client_secret, auth_code));
  
  (* Receive tokens *)
  in(secure, (access_token: bitstring, id_token: bitstring));
  
  (* Verify ID token *)
  let (=issuer, subject: bitstring, =client_id, =nonce_val, exp: bitstring) = 
    jwt_verify(id_token, pk(idp_signing_key)) in
  
  event idTokenVerified(subject, nonce_val);
  event userAuthenticated(subject);
  0.

(* OpenID Provider *)
let oidc_provider() =
  (* Receive authorization request *)
  in(c, (client_id_req: bitstring, redirect_uri_req: bitstring, 
         state_req: nonce, nonce_req: nonce, scope: bitstring));
  
  (* User authentication (abstracted) *)
  (* Generate authorization code *)
  new auth_code: nonce;
  out(c, (state_req, auth_code));
  
  (* Receive token request *)
  in(secure, (=client_id_req, client_secret_req: bitstring, =auth_code));
  
  (* Verify client *)
  if client_secret_req = client_secret then
  (
    (* Generate tokens *)
    new access_token: nonce;
    new subject: bitstring;
    
    (* Create ID token *)
    let id_token_claims = (issuer, subject, client_id_req, nonce_req, "1234567890") in
    let id_token = jwt_sign(id_token_claims, idp_signing_key) in
    
    event idTokenIssued(subject, nonce_req);
    out(secure, (access_token, id_token))
  ).

process
  (!oidc_client()) | (!oidc_provider())
```

## 4. Token Refresh Flow

```proverif
(* OAuth 2.0 Token Refresh Flow *)

free c: channel.
free secure: channel [private].

type nonce.
type token.

(* Token states *)
fun valid(token): bool.
fun expired(token): bool.
fun revoked(token): bool.

(* Events *)
event accessTokenIssued(token).
event refreshTokenIssued(token).
event tokenRefreshed(token, token).
event tokenRevoked(token).

(* Queries *)
query rt: token, at: token;
  event(tokenRefreshed(rt, at)) ==> event(refreshTokenIssued(rt)).

(* Client with refresh capability *)
let refresh_client() =
  (* Initial token request *)
  out(secure, client_credentials);
  in(secure, (access_token: token, refresh_token: token));
  
  (* Use access token... *)
  
  (* Refresh when expired *)
  out(secure, (refresh_token, client_id));
  in(secure, new_access_token: token);
  event tokenRefreshed(refresh_token, new_access_token);
  0.

(* Authorization server with refresh handling *)
let refresh_server() =
  (* Initial token issuance *)
  in(secure, creds: bitstring);
  new access_token: token;
  new refresh_token: token;
  event accessTokenIssued(access_token);
  event refreshTokenIssued(refresh_token);
  out(secure, (access_token, refresh_token));
  
  (* Handle refresh request *)
  in(secure, (refresh_req: token, client_req: bitstring));
  if valid(refresh_req) then
  (
    new new_access_token: token;
    event accessTokenIssued(new_access_token);
    out(secure, new_access_token)
  ).

process
  (!refresh_client()) | (!refresh_server())
```

## 5. Solid-OIDC WebID Authentication

```proverif
(* Solid-OIDC with WebID Authentication *)

free c: channel.
free pod_channel: channel [private].

type nonce.
type key.
type webid.

(* WebID operations *)
fun deriveWebID(key): webid.
fun validateWebID(webid, key): bool.

(* DPoP (Demonstration of Proof-of-Possession) *)
fun dpop_proof(bitstring, key): bitstring.
fun verify_dpop(bitstring, key): bool.

(* Constants *)
const solid_issuer: bitstring.

(* Private keys *)
free client_dpop_key: key [private].
free pod_key: key [private].

(* Events *)
event webidAuthenticated(webid).
event podAccessGranted(webid, bitstring).
event dpopVerified(key).

(* Queries *)
query id: webid, resource: bitstring;
  event(podAccessGranted(id, resource)) ==> event(webidAuthenticated(id)).

(* Solid-OIDC Client *)
let solid_client() =
  (* Generate DPoP key pair *)
  let client_webid = deriveWebID(client_dpop_key) in
  
  (* Authorization request with WebID *)
  new state: nonce;
  new nonce_val: nonce;
  out(c, (client_webid, redirect_uri, state, nonce_val));
  
  (* Receive authorization code *)
  in(c, (=state, auth_code: bitstring));
  
  (* Token request with DPoP proof *)
  let dpop_header = dpop_proof((solid_issuer, auth_code), client_dpop_key) in
  out(c, (auth_code, dpop_header, client_webid));
  
  (* Receive DPoP-bound access token *)
  in(c, dpop_access_token: bitstring);
  
  (* Access Pod resource with DPoP token *)
  new resource_uri: bitstring;
  let resource_dpop = dpop_proof(resource_uri, client_dpop_key) in
  out(pod_channel, (dpop_access_token, resource_dpop, resource_uri));
  
  (* Receive resource *)
  in(pod_channel, resource_data: bitstring);
  0.

(* Solid Identity Provider *)
let solid_idp() =
  (* Receive authorization request *)
  in(c, (webid_req: webid, redirect_req: bitstring, 
         state_req: nonce, nonce_req: nonce));
  
  (* Validate WebID (simplified) *)
  event webidAuthenticated(webid_req);
  
  (* Issue authorization code *)
  new auth_code: nonce;
  out(c, (state_req, auth_code));
  
  (* Receive token request with DPoP *)
  in(c, (=auth_code, dpop_header: bitstring, =webid_req));
  
  (* Verify DPoP proof *)
  if verify_dpop(dpop_header, pk(client_dpop_key)) then
  (
    event dpopVerified(pk(client_dpop_key));
    
    (* Issue DPoP-bound access token *)
    new dpop_token: bitstring;
    out(c, dpop_token)
  ).

(* Solid Pod Server *)
let solid_pod() =
  (* Receive resource request *)
  in(pod_channel, (access_token: bitstring, dpop_proof_req: bitstring, 
                    resource: bitstring));
  
  (* Verify DPoP-bound token and proof *)
  (* Simplified: assuming verification passes *)
  let webid = deriveWebID(client_dpop_key) in
  event podAccessGranted(webid, resource);
  
  (* Return resource *)
  new resource_content: bitstring;
  out(pod_channel, resource_content).

process
  (!solid_client()) | (!solid_idp()) | (!solid_pod())
```

## 6. Attack Scenarios

```proverif
(* OAuth 2.0 Attack Scenarios *)

(* Authorization Code Injection Attack *)
let malicious_client() =
  (* Intercept authorization code *)
  in(c, (state_leaked: nonce, code_leaked: bitstring));
  
  (* Try to use stolen code *)
  out(c, (attacker_client_id, attacker_secret, code_leaked, attacker_redirect));
  
  (* Check if token obtained *)
  in(c, stolen_token: bitstring);
  out(c, stolen_token).  (* Leak to attacker *)

(* CSRF Attack *)
let csrf_attacker() =
  (* Forge authorization request without state *)
  out(c, (victim_client_id, attacker_controlled_redirect, ""));
  
  (* Receive code at attacker's redirect *)
  in(c, auth_code: bitstring);
  out(c, auth_code).

(* Token Substitution Attack *)
let token_substitution() =
  (* Get legitimate token for attacker *)
  in(c, attacker_token: bitstring);
  
  (* Try to bind to victim's session *)
  out(c, (victim_session_id, attacker_token));
  
  (* Check if accepted *)
  in(c, result: bitstring).
```

## 7. Verification Commands

```bash
# Basic verification
proverif oauth_basic.pv

# With attack finding
proverif -test oauth_with_attacks.pv

# Generate attack trace
proverif -graph oauth_trace.pv

# HTML output
proverif -html output_dir oauth_complete.pv
```

## 8. Common ProVerif Patterns

### 8.1 Secrecy Queries
```proverif
query attacker(secret_value).
query attacker(access_token).
```

### 8.2 Authentication Correspondences
```proverif
(* Non-injective *)
query x:bitstring; event(endEvent(x)) ==> event(beginEvent(x)).

(* Injective (prevents replay) *)
query x:bitstring; inj-event(endEvent(x)) ==> inj-event(beginEvent(x)).
```

### 8.3 Observational Equivalence (Privacy)
```proverif
equiv
  !new s:bitstring; out(c, choice[s, s'])
  <=>
  !new s:bitstring; out(c, s).
```

## 9. Integration with WebSpi Library

The WebSpi library provides pre-built models for web protocols:

```proverif
(* Include WebSpi library *)
#include "webspi.pvl"

(* Use WebSpi HTTP model *)
let client_with_webspi() =
  httpRequest(uri, headers, body);
  httpResponse(status, response_headers, response_body).
```

## 10. Next Steps for Solid-OIDC Verification

1. **Adapt OAuth models** for Solid-specific flows
2. **Add WebID verification** logic
3. **Model DPoP mechanisms** for proof-of-possession
4. **Include pod ACL** verification
5. **Test against known attacks**
6. **Verify privacy properties** using equivalence

## Resources

- [ProVerif Manual](https://bblanche.gitlabpages.inria.fr/proverif/manual.pdf)
- [WebSpi Library](https://github.com/webspi/webspi)
- [OAuth 2.0 Security BCP](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [Solid-OIDC Specification](https://solidproject.org/TR/oidc)

---

*Document Version*: 1.0  
*Last Updated*: December 2024  
*Author*: Solid-OIDC Research Team