# New Claude Session Checklist

## What a New Session Should Know

### 1. Project Context ✓
- [ ] Project name: SolidAuth - decentralized auth gateway
- [ ] Goal: Auth0-like experience with Solid-OIDC
- [ ] Academic research for ArXiv publication

### 2. First Commands ✓
```bash
cat CHECKPOINT.md          # Check for work in progress
gh issue list --state open  # See what needs doing
git log --oneline -5        # Recent work
cat CONTEXT_PROTOCOL.md     # Understand context preservation
```

### 3. Core Principles ✓
- [ ] YAGNI-first: Build simplest thing that works
- [ ] One issue per session
- [ ] 30-minute checkpoints
- [ ] Verify everything with Tavily

### 4. Tool Usage ✓
- [ ] **gh CLI**: All GitHub operations (issues, PRs, projects)
- [ ] **Sequential Thinking**: Complex reasoning/planning
- [ ] **Tavily**: Verify citations and research
- [ ] **TodoWrite**: Track task progress

### 5. Anti-Patterns to Avoid ✓
- [ ] Over-engineering (creating frameworks)
- [ ] Working on multiple issues
- [ ] Citing without verification
- [ ] Creating docs unless asked
- [ ] Working past 30 minutes without checkpoint

### 6. Workflow ✓
```bash
# Standard Issue Flow
1. gh issue view [NUMBER]
2. Create TodoWrite list
3. Work for 30 minutes
4. Update CHECKPOINT.md
5. git commit -m "Progress on #[NUMBER]"
6. Close session or continue
```

### 7. Research Protocol ✓
- [ ] Search with Tavily first
- [ ] Verify every citation
- [ ] Save to CHECKPOINT.md immediately
- [ ] Commit after each verified finding

### 8. Key Files ✓
- `CLAUDE.md` - Project instructions and principles
- `CONTEXT_PROTOCOL.md` - How to prevent context degradation
- `CHECKPOINT.md` - Current work state
- `CHECKPOINT.md.example` - Example checkpoint format
- `/Users/erdalgunes/.claude/CLAUDE.md` - Global YAGNI principles

### 9. GitHub Commands ✓
```bash
gh issue list               # List issues
gh issue view 4             # View issue #4
gh issue close 4 -c "Done"  # Close issue
gh pr create                # Create pull request
gh project item-list 3 --owner erdalgunes  # View project
```

### 10. Emergency Recovery ✓
If context feels degraded:
```bash
cat CLAUDE.md               # Re-read principles
cat CONTEXT_PROTOCOL.md     # Re-read protocol
cat CHECKPOINT.md           # See current state
git log --oneline -10      # See recent work
# Then checkpoint and start fresh
```

## Test Questions for New Session

1. **Q**: How do you start work on issue #5?
   **A**: 
   ```bash
   cat CHECKPOINT.md
   gh issue view 5
   # Create TodoWrite list
   # Set 30-minute timer
   ```

2. **Q**: Found a paper citation in memory. What to do?
   **A**: Verify with Tavily before using it

3. **Q**: Been working for 25 minutes. What to do?
   **A**: Prepare to checkpoint at 30 minutes

4. **Q**: Need to create a new framework for X?
   **A**: STOP. YAGNI. Is it used 3+ times?

5. **Q**: How to close an issue?
   **A**: `gh issue close [NUMBER] -c "Completed"`

## Success Criteria
A new Claude session understands this protocol when it:
- ✅ Checks CHECKPOINT.md first
- ✅ Uses gh for GitHub operations
- ✅ Uses Tavily to verify research
- ✅ Uses sequential thinking for complex reasoning
- ✅ Checkpoints every 30 minutes
- ✅ Works on one issue only
- ✅ Follows YAGNI principles

---
**If all boxes checked, the protocol is complete and understandable.**