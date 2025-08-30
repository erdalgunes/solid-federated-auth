# Context Preservation Protocol

## Problem
Claude has limited context window and forgets YAGNI principles and project rules during long sessions, leading to over-engineering and potential hallucinations in research.

## Solution: Simple Checkpointing

### 1. Session Rules
- **One Issue Per Session**: Never work on multiple issues in one Claude instance
- **30-Minute Chunks**: Break work into ~30 minute segments
- **Checkpoint Commits**: End each chunk with a git commit

### 2. Research Protocol
```bash
# Before writing any research finding:
1. Verify citations with Tavily
2. Check papers actually exist
3. Confirm quotes are accurate
4. Save to CHECKPOINT.md
```

### 3. Checkpoint Format
Each work session creates/updates `CHECKPOINT.md`:
```markdown
## Current Issue: #[number]
## Session: [timestamp]
## Completed:
- [ ] Task 1
- [x] Task 2
## Key Findings:
- Finding with verified citation
## Next Steps:
- What to do next session
```

### 4. New Session Start
```bash
# When starting new Claude session:
1. gh issue view [number]
2. cat CHECKPOINT.md  # if exists
3. git log --oneline -5
4. Continue from checkpoint
```

### 5. Anti-Hallucination Rules
- **Never cite without verifying**: Use Tavily to confirm papers exist
- **Never assume libraries exist**: Check package.json/requirements.txt
- **Never create unless asked**: No proactive documentation
- **Never over-abstract**: Used <3 times = don't extract

### 6. Implementation Workflow
```bash
# Standard flow for each issue:
1. gh issue view [number]
2. Create TodoWrite list from requirements
3. Work for ~30 minutes
4. Update CHECKPOINT.md
5. git add -A && git commit -m "Progress on #[number]: [what you did]"
6. If not done, close session
7. New session continues from checkpoint
```

### 7. Research-Specific Workflow
```bash
# For literature review tasks:
1. Search with Tavily first
2. Verify each citation
3. Save to CHECKPOINT.md immediately
4. Commit after each paper reviewed
5. Never trust memory - always verify
```

## Why This Works
- **Simple**: No new tools or dependencies
- **Effective**: Git provides natural checkpoints  
- **Verifiable**: Everything tracked in commits
- **YAGNI-compliant**: Minimal overhead
- **Anti-hallucination**: Forced verification

## Example Session
```bash
# Session 1 (30 mins)
gh issue view 5
# Create todo list
# Research 2 papers with Tavily
# Save to CHECKPOINT.md
git commit -m "Issue #5: Reviewed quantum computing papers"

# Session 2 (new Claude, 30 mins)  
cat CHECKPOINT.md  # See what was done
gh issue view 5
# Continue from checkpoint
# Research 2 more papers
git commit -m "Issue #5: Completed literature review"
gh issue close 5
```

## Emergency Recovery
If context degraded:
```bash
git log --oneline -10  # See what was done
cat CLAUDE.md  # Re-read principles
cat CHECKPOINT.md  # See current state
# Start fresh with clear context
```

---
**Remember**: Working code > Perfect code. Small commits > Big rewrites.