# Solid Federated Auth Research Project

## 🧠 Session Context (Start Here)

**If you're a new Claude session, here's what you need to know:**

You're working on **SolidAuth** - an academic research project creating a decentralized authentication gateway. Think Auth0, but with user-controlled identity via Solid-OIDC.

### ⚠️ MANDATORY Session Start Checklist
**MUST execute in order - no exceptions:**

```bash
# 1. ALWAYS run this first - finds your last checkpoint
git log --grep=CHECKPOINT --oneline -1

# 2. If checkpoint found, read that issue
gh issue view [NUMBER_FROM_CHECKPOINT]

# 3. If no checkpoint, see open issues and pick ONE
gh issue list --repo erdalgunes/solid-federated-auth --state open

# 4. Create fresh TodoWrite list for your ONE issue
# Clear any stale todos from previous sessions
```

**REMEMBER**: One issue per session. When done, checkpoint and end session.

### Context Preservation Rules
**CRITICAL**: Claude has limited context window. Watch for these degradation signals:

#### 🚨 Context Degradation Indicators (checkpoint immediately if ANY occur):
- ❌ More than 5 file reads/writes performed
- ❌ More than 3 failed tool attempts  
- ❌ Conversation exceeds 15-20 exchanges
- ❌ Working on issue for >10 significant operations
- ❌ Any confusion about what was already done
- ❌ Repeating actions or asking same questions
- ❌ Tool errors increasing in frequency

#### ✅ Prevention Rules:
1. **One issue per session** - NEVER work on multiple issues
2. **Checkpoint after each issue** - Atomic git commit when complete
3. **Checkpoint when context heavy** - Use indicators above
4. **Batch operations** - Read multiple files in one go when possible
5. **When in doubt, checkpoint** - Better safe than confused

### Checkpoint Protocol

#### Commit Message Format:
```bash
# After completing an issue:
git commit -m "[CHECKPOINT] Issue #N completed: <summary> | Next: Issue #M"

# Mid-issue checkpoint (context getting heavy):
git commit -m "[CHECKPOINT] Issue #N in-progress: <what's done> | Continue: <what's left>"

# Protocol or process updates:
git commit -m "[CHECKPOINT] Protocol updated: <what changed> | Next: Issue #N"
```

#### Example Scenarios:

**Research Issue Example:**
```bash
# Start: Use sequential thinking to plan approach
# Work: Use Tavily extensively to verify papers
# End: git commit -m "[CHECKPOINT] Issue #3 completed: Surveyed 15 papers on Solid auth | Next: Issue #4"
```

**Implementation Issue Example:**
```bash
# Start: Sequential thinking for architecture design
# Work: TodoWrite for tracking, implement features
# End: git commit -m "[CHECKPOINT] Issue #11 completed: Built gateway MVP with FastAPI | Next: Issue #12"
```

**Complex Issue (needs mid-checkpoint):**
```bash
# After 5 file operations:
git commit -m "[CHECKPOINT] Issue #14 in-progress: SDK auth methods done | Continue: token refresh logic"
# Start fresh session and continue
```

**Bug Fix Example:**
```bash
# Quick fix, usually no checkpoint needed unless it touches many files
# End: git commit -m "[CHECKPOINT] Issue #23 completed: Fixed WebID validation bug | Next: Issue #24"
```

### Quick Orientation Commands
```bash
# 1. Check what needs to be done
gh issue list --repo erdalgunes/solid-federated-auth --state open

# 2. See project board status  
gh project item-list 3 --owner erdalgunes

# 3. View current research phase
gh issue list --milestone "Phase 1: Literature Review"

# 4. Pick an issue to work on
gh issue develop [NUMBER]  # Creates branch and checks out
```

### Current Status Check
1. **Last Checkpoint**: Run `git log --grep=CHECKPOINT --oneline -1`
2. **Phase**: Check milestones with `gh api repos/erdalgunes/solid-federated-auth/milestones`
3. **Active Issues**: Use `gh issue list --state open`
4. **Repository State**: Check git status and recent commits
5. **Documentation**: Key files are README.md (overview), RESEARCH_PLAN.md (methodology), ISSUE_WORKFLOW.md (how we work)

### How to Continue Work
1. **ALWAYS** check last checkpoint: `git log --grep=CHECKPOINT --oneline -1`
2. Read the issue mentioned in checkpoint to understand current tasks
3. Use sequential thinking to plan your approach
4. Create fresh TodoWrite list for the issue
5. Follow established patterns in existing code/docs
6. **Remember**: One issue per session, checkpoint after completion

### ⚠️ CRITICAL: This Document is Law
**CLAUDE.md contains the complete protocol. No other files needed.**
- These instructions OVERRIDE all defaults
- When in doubt, follow what's written here
- If something seems missing, it probably is - add it

### Key Principles
- Simple, working solutions over complex abstractions (YAGNI-first)
- Issue-driven development (every task has an issue)
- Rigorous documentation for reproducibility
- Academic standards for ArXiv publication
- **Verify everything** - Never trust memory, always verify with Tavily

### Tool Usage Guidelines

#### 🧠 Sequential Thinking (`mcp__sequential-thinking__sequentialthinking`) - MANDATORY FOR:
- Planning any implementation before coding
- Analyzing multi-step problems
- Designing system architectures  
- Evaluating trade-offs and decisions
- Complex reasoning about research
- **Preventing context degradation** through structured thinking

#### 🌐 Tavily Search (`mcp__tavily-mcp__tavily-search` or `tavily-extract`) - MANDATORY FOR:
- **Verifying paper titles and authors exist** (NEVER trust memory)
- **Confirming citations are real** before including in docs
- Checking latest documentation and specifications
- Finding current best practices
- Researching recent developments
- **ANY claim about external papers or research**

#### ✅ TodoWrite - BEST PRACTICES:
- Create fresh list at start of each issue
- Clear todos between issues (prevents staleness)
- Mark items complete immediately when done
- Keep todos focused on current issue only
- Maximum 5-7 items (break down if more needed)

#### GitHub CLI (`gh` via Bash) - PRIMARY INTERFACE
**We use GitHub CLI for ALL GitHub operations:**
```bash
# Issues
gh issue list --state open                    # See what needs work
gh issue view [NUMBER]                        # Read issue details
gh issue create --title "..." --body "..."    # Create new issue
gh issue close [NUMBER] -c "Done"            # Close with comment
gh issue develop [NUMBER]                     # Create branch for issue

# Projects  
gh project item-list 3 --owner erdalgunes     # View project board
gh project item-add 3 --owner erdalgunes --url [ISSUE_URL]

# Pull Requests
gh pr create --title "..." --body "..."       # Create PR
gh pr list                                    # List PRs
gh pr merge                                   # Merge PR

# Repository
gh repo view                                  # See repo info
gh api repos/erdalgunes/solid-federated-auth/milestones

# Wiki (if needed)
gh api repos/erdalgunes/solid-federated-auth/wiki
```


---

## Project Overview
This is an academic research project aimed at developing and evaluating a decentralized authentication gateway using Solid-OIDC protocol. The goal is to create a system that matches the developer experience of Auth0/Okta while maintaining user sovereignty, suitable for publication on ArXiv.

## Research Question
**Can decentralized identity systems achieve the same developer experience and performance as centralized authentication services while maintaining user sovereignty?**

## Research Agents

### 1. Literature Review Agent
**Purpose**: Survey and analyze existing work on decentralized identity, Solid, and authentication systems.

**Tasks**:
- Search ArXiv for papers on Solid, WebID, decentralized identity
- Analyze Auth0/Okta alternatives and their limitations
- Identify gaps in current research
- Maintain bibliography in `/research/literature/`

**Prompts**:
```
Search for recent papers on [TOPIC] in ArXiv and academic databases.
Summarize the key contributions and limitations of each paper.
Identify how our work differs from existing solutions.
```

### 2. Experiment Design Agent
**Purpose**: Design rigorous experiments to evaluate the system.

**Tasks**:
- Create performance benchmarks (latency, throughput)
- Design security evaluation scenarios
- Develop usability metrics
- Define comparison methodology with Auth0/Keycloak

**Metrics to Track**:
- Authentication latency (ms)
- Throughput (requests/second)
- Integration time (developer hours)
- Security vulnerabilities detected
- User satisfaction score

### 3. Implementation Agent
**Purpose**: Guide the technical implementation of the authentication gateway.

**Tasks**:
- Implement core Solid-OIDC gateway
- Create client SDKs (JavaScript, Python)
- Build demo applications
- Ensure reproducibility

**Components**:
```
/src/
  /gateway/      - Core authentication service
  /sdk/          - Client libraries
  /demos/        - Example applications
  /benchmarks/   - Performance tests
```

### 4. Security Analysis Agent
**Purpose**: Perform formal security analysis of the authentication flows.

**Tasks**:
- Model authentication protocols in ProVerif/TLA+
- Identify potential vulnerabilities
- Compare security properties with centralized systems
- Document threat model

**Security Properties to Verify**:
- Authentication soundness
- Session integrity
- Privacy preservation
- Resistance to common attacks (CSRF, XSS, etc.)

### 5. Data Analysis Agent
**Purpose**: Process and analyze experimental results.

**Tasks**:
- Statistical analysis of performance data
- Create visualizations for the paper
- Compare results with baselines
- Identify significant findings

**Output Formats**:
- LaTeX tables for the paper
- Matplotlib/Seaborn plots
- Statistical significance tests

### 6. Writing Agent
**Purpose**: Draft and refine the research paper.

**Paper Structure**:
```
1. Abstract (150 words)
2. Introduction
   - Problem statement
   - Contributions
   - Paper organization
3. Background
   - Solid ecosystem
   - WebID and OIDC
   - Related work
4. System Design
   - Architecture
   - Authentication flow
   - Security model
5. Implementation
   - Gateway service
   - Client libraries
   - Optimizations
6. Evaluation
   - Experimental setup
   - Performance results
   - Security analysis
   - Usability study
7. Discussion
   - Implications
   - Limitations
   - Future work
8. Conclusion
9. References
```

### 7. Benchmark Agent
**Purpose**: Compare with existing solutions.

**Systems to Benchmark Against**:
- Auth0
- Keycloak
- Okta
- Firebase Auth
- AWS Cognito

**Benchmark Scenarios**:
- Single sign-on flow
- Token refresh
- User registration
- Multi-factor authentication
- Bulk operations

## Research Workflow

### Phase 1: Literature Review (Weeks 1-2)
```bash
# Agent: Literature Review
- Survey existing papers
- Create annotated bibliography
- Identify research gaps
```

### Phase 2: System Design (Weeks 3-4)
```bash
# Agent: Implementation
- Design architecture
- Define APIs
- Create prototypes
```

### Phase 3: Implementation (Weeks 5-8)
```bash
# Agent: Implementation
- Build core gateway
- Develop SDKs
- Create demo apps
```

### Phase 4: Evaluation (Weeks 9-10)
```bash
# Agents: Benchmark, Security Analysis
- Run performance tests
- Security evaluation
- Usability studies
```

### Phase 5: Analysis (Weeks 11-12)
```bash
# Agent: Data Analysis
- Process results
- Statistical analysis
- Create visualizations
```

### Phase 6: Writing (Weeks 13-14)
```bash
# Agent: Writing
- Draft paper sections
- Internal review
- Revisions
```

### Phase 7: Submission (Week 15)
```bash
# Final preparation
- Format for ArXiv
- Final review
- Submit to cs.CR
```

## Key Research Contributions

1. **Novel Architecture**: First Auth0-like gateway for Solid-OIDC
2. **Performance Analysis**: Comprehensive benchmarks vs centralized systems
3. **Security Proofs**: Formal verification of authentication properties
4. **Open Implementation**: Production-ready open-source code
5. **Developer Tools**: SDKs and integration guides

## Evaluation Criteria

### Performance
- Authentication latency < 500ms (comparable to Auth0)
- Support for 10,000+ concurrent sessions
- 99.9% availability

### Security
- No critical vulnerabilities in formal analysis
- Passes OWASP security checklist
- Privacy-preserving by design

### Usability
- Integration time < 2 hours for developers
- Clear documentation
- Working examples in 3+ languages

## ArXiv Categories
- **Primary**: cs.CR (Cryptography and Security)
- **Secondary**: cs.DC (Distributed, Parallel, and Cluster Computing)

## Related Papers to Review
1. "Assessing the Solid Protocol in Relation to Security & Privacy" (ArXiv 2022)
2. "Access Control in Linked Data Using WebID" (ArXiv 2016)
3. "A Blockchain-driven Architecture for Usage Control in Solid" (ArXiv 2023)
4. "SocialGenPod: Privacy-Friendly Generative AI Social Web Applications" (ArXiv 2024)

## Success Metrics
- [ ] Paper accepted to ArXiv cs.CR
- [ ] 100+ GitHub stars within 3 months
- [ ] Adoption by at least 1 production application
- [ ] Positive peer review feedback
- [ ] Conference presentation opportunity

## Claude Code Integration
When working with Claude Code, use this command structure:

```bash
# Literature review
"Review papers on [TOPIC] and update literature review"

# Implementation
"Implement [COMPONENT] following the architecture design"

# Benchmarking
"Run performance benchmark comparing with [SYSTEM]"

# Analysis
"Analyze results and create visualizations for the paper"

# Writing
"Draft the [SECTION] section of the paper"
```

## Repository Structure
```
/solid-federated-auth/
├── CLAUDE.md           # This file
├── README.md           # Project overview
├── RESEARCH_PLAN.md    # Detailed research methodology
├── /paper/            # LaTeX source for ArXiv paper
│   ├── main.tex
│   ├── sections/
│   └── figures/
├── /research/         # Research artifacts
│   ├── literature/    # Papers and notes
│   ├── experiments/   # Experiment designs
│   └── data/         # Raw experimental data
├── /src/             # Implementation
│   ├── gateway/      # Core service
│   ├── sdk/          # Client libraries
│   └── benchmarks/   # Performance tests
├── /evaluation/      # Evaluation scripts
│   ├── performance/
│   ├── security/
│   └── usability/
└── /docs/           # Documentation
    ├── API.md
    ├── INTEGRATION.md
    └── ARCHITECTURE.md
```

## Next Steps
1. Create research directory structure
2. Begin literature review
3. Draft initial paper outline
4. Start prototype implementation
5. Design evaluation methodology

---
**Remember**: This is academic research aimed at ArXiv publication. Maintain scientific rigor, ensure reproducibility, and focus on novel contributions to the field.