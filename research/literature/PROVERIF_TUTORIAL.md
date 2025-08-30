# ProVerif Tutorial for Authentication Protocol Verification

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Concepts](#basic-concepts)
4. [Writing Your First Model](#writing-your-first-model)
5. [Verifying Security Properties](#verifying-security-properties)
6. [Advanced Features](#advanced-features)
7. [Debugging and Troubleshooting](#debugging-and-troubleshooting)
8. [OAuth/OIDC Specific Patterns](#oauthoidc-specific-patterns)

## 1. Introduction

ProVerif is an automatic cryptographic protocol verifier in the Dolev-Yao model. It can verify:
- Secrecy properties
- Authentication properties
- Observational equivalence (privacy)
- Correspondence assertions

### Key Advantages
- Fully automated verification
- Handles unbounded number of sessions
- Well-suited for authentication protocols
- Extensive documentation and examples

## 2. Installation

### macOS
```bash
brew install proverif
```

### Linux
```bash
# Ubuntu/Debian
apt-get install proverif

# From source
wget https://bblanche.gitlabpages.inria.fr/proverif/proverif2.05.tar.gz
tar -xzf proverif2.05.tar.gz
cd proverif2.05
./build
sudo make install
```

### Verification
```bash
proverif -help
```

## 3. Basic Concepts

### 3.1 Applied Pi-Calculus Foundation

ProVerif is based on applied pi-calculus with:
- **Processes**: Protocol participants
- **Channels**: Communication medium
- **Terms**: Messages and data
- **Events**: Observable actions

### 3.2 Syntax Overview

```proverif
(* Comments use this syntax *)

(* Channel declaration *)
free c: channel.                    (* Public channel *)
free secure: channel [private].     (* Private channel *)

(* Type declaration *)
type nonce.
type key.

(* Function declaration *)
fun encrypt(bitstring, key): bitstring.

(* Destructor with reduction *)
reduc forall m: bitstring, k: key; 
      decrypt(encrypt(m, k), k) = m.
```

### 3.3 Process Syntax

```proverif
(* Basic process operations *)
0                           (* Null process *)
P | Q                      (* Parallel composition *)
!P                         (* Replication (infinite copies) *)
new n: nonce; P            (* Name generation *)
out(c, M); P              (* Output *)
in(c, x: bitstring); P    (* Input *)
if M = N then P else Q    (* Conditional *)
let x = M in P            (* Pattern matching *)
```

## 4. Writing Your First Model

### 4.1 Simple Authentication Protocol

```proverif
(* simple_auth.pv - A basic authentication protocol *)

(* === Declarations === *)
free c: channel.

type nonce.
type key.

(* Shared key *)
free k: key [private].

(* Cryptographic primitives *)
fun senc(bitstring, key): bitstring.
reduc forall m: bitstring, k: key; 
      sdec(senc(m, k), k) = m.

(* === Events === *)
event beginAuth(bitstring).
event endAuth(bitstring).

(* === Security Queries === *)
(* Secrecy *)
query attacker(k).

(* Authentication *)
query x: bitstring; 
      event(endAuth(x)) ==> event(beginAuth(x)).

(* === Protocol Processes === *)
let client(k: key) =
  new n: nonce;
  event beginAuth(n);
  out(c, senc(n, k));
  in(c, m: bitstring);
  let (=n) = sdec(m, k) in
  event endAuth(n).

let server(k: key) =
  in(c, m: bitstring);
  let n: nonce = sdec(m, k) in
  out(c, senc(n, k)).

(* === Main Process === *)
process
  (!client(k)) | (!server(k))
```

### 4.2 Running the Verification

```bash
# Basic verification
proverif simple_auth.pv

# Generate HTML output
proverif -html output simple_auth.pv

# Show attack trace if found
proverif -graph simple_auth.pv
```

## 5. Verifying Security Properties

### 5.1 Secrecy Properties

```proverif
(* Basic secrecy query *)
query attacker(secret).

(* Conditional secrecy *)
query attacker(secret) phase 1.

(* Strong secrecy using choice *)
noninterf secret.
```

### 5.2 Authentication Properties

```proverif
(* Non-injective agreement *)
event beginSession(bitstring, bitstring).
event endSession(bitstring, bitstring).

query a: bitstring, b: bitstring;
      event(endSession(a, b)) ==> event(beginSession(a, b)).

(* Injective agreement (prevents replay) *)
query a: bitstring, b: bitstring;
      inj-event(endSession(a, b)) ==> inj-event(beginSession(a, b)).
```

### 5.3 Privacy Properties

```proverif
(* Observational equivalence *)
free choice: bool [private].

process
  if choice then
    new s1: bitstring; out(c, s1)
  else
    new s2: bitstring; out(c, s2)
```

## 6. Advanced Features

### 6.1 Tables (State)

```proverif
(* Declare a table *)
table keys(bitstring, key).

(* Insert into table *)
insert keys(client_id, client_key);

(* Query table *)
get keys(=client_id, k) in
  (* Use k *)
```

### 6.2 Phases

```proverif
(* Model protocol evolution *)
phase 0.
  (* Initial protocol *)

phase 1.
  (* After key compromise *)
```

### 6.3 Equational Theories

```proverif
(* Diffie-Hellman *)
const g: bitstring.
fun exp(bitstring, bitstring): bitstring.

equation forall x: bitstring, y: bitstring;
  exp(exp(g, x), y) = exp(exp(g, y), x).
```

## 7. Debugging and Troubleshooting

### 7.1 Common Issues

**Non-termination**
```proverif
(* Add depth bounds *)
set maxDepth = 20.

(* Simplify equivalences *)
set simplifyDerivation = true.
```

**False Attacks**
```proverif
(* Use precise models *)
set preciseActions = true.

(* Add type constraints *)
in(c, x: nonce)  (* Instead of x: bitstring *)
```

### 7.2 Debugging Techniques

```proverif
(* Add trace output *)
set traceDisplay = long.

(* Show derivation *)
set explainDerivation = true.

(* Interactive mode *)
set interactiveSwat = true.
```

## 8. OAuth/OIDC Specific Patterns

### 8.1 Modeling HTTP Redirects

```proverif
(* Browser redirect *)
let browser() =
  in(c, (location: bitstring, params: bitstring));
  (* Follow redirect *)
  out(c, (location, params)).
```

### 8.2 State Parameter for CSRF

```proverif
let oauth_client() =
  new state: nonce;
  (* Include in auth request *)
  out(c, (client_id, redirect_uri, state));
  
  (* Verify on return *)
  in(c, (=state, code: bitstring));
  (* State matches - CSRF prevented *)
```

### 8.3 PKCE Verification

```proverif
(* Code challenge/verifier *)
fun sha256(bitstring): bitstring.

let pkce_flow() =
  new verifier: nonce;
  let challenge = sha256(verifier) in
  out(c, challenge);
  (* ... *)
  out(c, verifier);
  (* Server verifies: sha256(verifier) = challenge *)
```

### 8.4 Token Binding

```proverif
(* DPoP-style binding *)
fun sign_dpop(bitstring, key): bitstring.

let dpop_client(client_key: key) =
  let proof = sign_dpop((method, uri), client_key) in
  out(c, (token, proof)).
```

## 9. Complete OAuth Example

```proverif
(* oauth_complete.pv *)

free c: channel.
free secure: channel [private].

type nonce.
type token.

(* Client credentials *)
const client_id: bitstring.
const client_secret: bitstring [private].

(* Events *)
event clientAuthorized(bitstring).
event tokenIssued(bitstring, token).

(* Queries *)
query attacker(client_secret).

query t: token;
  event(tokenIssued(client_id, t)) ==> 
  event(clientAuthorized(client_id)).

(* OAuth Client *)
let oauth_client() =
  (* Authorization request *)
  new state: nonce;
  out(c, (client_id, redirect_uri, state));
  
  (* Authorization response *)
  in(c, (=state, code: bitstring));
  
  (* Token request *)
  out(secure, (client_id, client_secret, code));
  
  (* Token response *)
  in(secure, access_token: token);
  event tokenIssued(client_id, access_token).

(* Authorization Server *)
let auth_server() =
  (* Authorization endpoint *)
  in(c, (cid: bitstring, ruri: bitstring, st: nonce));
  event clientAuthorized(cid);
  new code: nonce;
  out(c, (st, code));
  
  (* Token endpoint *)
  in(secure, (=cid, cs: bitstring, =code));
  if cs = client_secret then
    new token: token;
    out(secure, token).

(* Main *)
process
  (!oauth_client()) | (!auth_server())
```

## 10. Best Practices

### 10.1 Model Organization

```proverif
(* 1. Declarations *)
(* 2. Cryptographic primitives *)
(* 3. Events *)
(* 4. Queries *)
(* 5. Helper processes *)
(* 6. Main protocol processes *)
(* 7. Main process composition *)
```

### 10.2 Verification Strategy

1. Start with basic secrecy
2. Add authentication properties
3. Check for replay attacks
4. Verify privacy properties
5. Test with compromised keys

### 10.3 Documentation

```proverif
(* === PROTOCOL: OAuth 2.0 + PKCE === *)
(* Author: Your Name *)
(* Date: 2024-12-30 *)
(* Purpose: Verify PKCE prevents code injection *)

(* Security Goals:
   - Authorization code secrecy
   - Client authentication
   - CSRF prevention via state
   - Code injection prevention via PKCE
*)
```

## 11. Resources and References

### Official Documentation
- [ProVerif Manual v2.05](https://bblanche.gitlabpages.inria.fr/proverif/manual.pdf)
- [ProVerif Examples](https://bblanche.gitlabpages.inria.fr/proverif/)

### Academic Papers
- Blanchet, B. (2016). "Modeling and Verifying Security Protocols with the Applied Pi Calculus and ProVerif"
- Fett et al. (2016). "A Comprehensive Formal Security Analysis of OAuth 2.0"

### Community Resources
- [WebSpi Library](https://github.com/webspi/webspi) - Web protocol models
- [ProVerif Mailing List](https://lists.gforge.inria.fr/mailman/listinfo/proverif-users)

## 12. Quick Reference Card

```proverif
(* === Common Patterns === *)

(* Nonce generation *)
new n: nonce;

(* Symmetric encryption *)
senc(message, key) / sdec(ciphertext, key)

(* Asymmetric encryption *)
aenc(message, pk(sk)) / adec(ciphertext, sk)

(* Digital signature *)
sign(message, sk) / checksign(signature, pk(sk))

(* Hash function *)
hash(message)

(* Equality test *)
if x = y then P else Q

(* Pattern matching *)
let (a, b) = pair in P

(* Table operations *)
insert table(key, value);
get table(=key, x) in P

(* Events *)
event eventName(params);

(* Basic queries *)
query attacker(secret).
query event(e2) ==> event(e1).
```

---

*Tutorial Version*: 1.0  
*Last Updated*: December 2024  
*For ProVerif Version*: 2.05