# GitHub Issue Workflow for Research Orchestration

## Overview
This document describes how we use GitHub Issues to orchestrate our academic research project. The issue tracking system ensures rigorous project management, reproducibility, and collaboration throughout the research lifecycle.

## Issue-Driven Research Methodology

### Why GitHub Issues for Research?
1. **Traceability**: Every research decision and task is documented
2. **Collaboration**: Multiple researchers can coordinate effectively
3. **Accountability**: Clear ownership and deadlines
4. **Reproducibility**: Complete record of research process
5. **Integration**: Links code, data, and documentation

## Issue Structure

### Issue Templates
We have 6 specialized issue templates in `.github/ISSUE_TEMPLATE/`:

1. **Literature Review** (`01-literature-review.md`)
   - For surveying academic papers
   - Documenting research gaps
   - Building theoretical foundation

2. **Implementation** (`02-implementation.md`)
   - System component development
   - Feature implementation
   - Code architecture tasks

3. **Experiment** (`03-experiment.md`)
   - Experimental design
   - Data collection procedures
   - Evaluation protocols

4. **Analysis** (`04-analysis.md`)
   - Statistical analysis
   - Data visualization
   - Results interpretation

5. **Writing** (`05-writing.md`)
   - Paper section drafting
   - Documentation creation
   - Revision tasks

6. **Bug Report** (`06-bug-report.md`)
   - Technical issues
   - Implementation problems
   - Blocking issues

## Labels System

### Phase Labels (Timeline)
- `Phase-1` - Literature Review (Weeks 1-2)
- `Phase-2` - Design & Implementation (Weeks 3-8)
- `Phase-3` - Evaluation (Weeks 9-11)
- `Phase-4` - Analysis (Weeks 12-13)
- `Phase-5` - Writing & Submission (Weeks 14-15)

### Work Type Labels
- `research` - Research and investigation
- `literature-review` - Paper analysis
- `implementation` - Code development
- `experiment` - Running evaluations
- `analysis` - Data processing
- `writing` - Documentation/paper
- `security` - Security analysis
- `performance` - Performance optimization

### Priority Labels
- `priority-high` - Critical for timeline
- `priority-low` - Nice to have
- `blocked` - Waiting on dependencies
- `help-wanted` - Needs assistance
- `needs-review` - Requires peer review

## Milestones

Our research is organized into 5 milestones:

1. **Phase 1: Literature Review** (Due: Feb 13, 2025)
   - Survey existing work
   - Identify research gaps

2. **Phase 2: System Design & Implementation** (Due: Mar 27, 2025)
   - Architecture design
   - Core system build

3. **Phase 3: Evaluation** (Due: Apr 17, 2025)
   - Run experiments
   - Collect data

4. **Phase 4: Analysis & Writing** (Due: May 8, 2025)
   - Analyze results
   - Draft paper

5. **Phase 5: ArXiv Submission** (Due: May 15, 2025)
   - Final review
   - Submit to ArXiv

## Workflow Process

### 1. Creating Issues
```bash
# Use gh CLI to create issues
gh issue create --title "[TYPE] Task description" \
  --label "appropriate-labels" \
  --milestone "Phase X: Name" \
  --assignee @me
```

### 2. Issue Lifecycle
```
Created → Assigned → In Progress → Review → Completed
```

### 3. Working on Issues
1. **Claim**: Assign yourself to the issue
2. **Branch**: Create feature branch: `feature/issue-{number}`
3. **Work**: Implement/research/analyze
4. **Document**: Update relevant docs
5. **PR**: Create pull request linking issue
6. **Close**: Auto-close via PR merge

### 4. Linking Work
- Reference issues in commits: `Addresses #123`
- Close issues via PR: `Fixes #123`
- Cross-reference: `Related to #456`

## Project Board Setup

### Manual Setup (Required due to auth limitations)
1. Go to: https://github.com/erdalgunes/solid-federated-auth/projects
2. Click "New project"
3. Select "Board" view
4. Name: "SolidAuth Research Roadmap"

### Recommended Columns
1. **Backlog** - All unstarted issues
2. **This Week** - Current sprint focus
3. **In Progress** - Active work
4. **In Review** - Awaiting review
5. **Done** - Completed work

### Automation Rules
- New issues → Backlog
- Assigned issues → This Week
- PRs created → In Review
- Merged PRs → Done

## Research Agent Mapping

Each issue type maps to research agents defined in [CLAUDE.md](./CLAUDE.md):

| Issue Type | Responsible Agent | Deliverables |
|------------|------------------|--------------|
| Literature Review | Literature Review Agent | Bibliography, summaries |
| Implementation | Implementation Agent | Code, tests, docs |
| Experiment | Experiment Design Agent | Data, protocols |
| Analysis | Data Analysis Agent | Statistics, visualizations |
| Writing | Writing Agent | Paper sections |
| Security | Security Analysis Agent | Proofs, reports |

## Best Practices

### Issue Creation
- Use templates for consistency
- Clear, specific titles with `[TYPE]` prefix
- Define acceptance criteria
- Link dependencies
- Assign to milestone

### Issue Management
- Update status regularly
- Comment on blockers
- Link related PRs
- Document decisions
- Close when complete

### Collaboration
- Tag colleagues for review: `@username`
- Use discussions for complex topics
- Regular status updates
- Share findings in comments

## Example Workflow

### Week 1: Literature Review
```bash
# Create literature review issue
gh issue create --title "[LITERATURE] OAuth security papers" \
  --label "research,literature-review,Phase-1" \
  --milestone "Phase 1: Literature Review"

# Work on issue
git checkout -b feature/issue-1-oauth-papers
# ... do research ...
git commit -m "Add OAuth security papers to bibliography #1"
git push origin feature/issue-1-oauth-papers

# Create PR
gh pr create --title "Literature: OAuth security analysis" \
  --body "Fixes #1 - Added 10 papers on OAuth security"
```

## Progress Tracking

### Weekly Reviews
Every Friday:
1. Review completed issues
2. Update project board
3. Plan next week's issues
4. Document blockers

### Phase Transitions
At milestone completion:
1. Review all issues closed
2. Document lessons learned
3. Create issues for next phase
4. Update README progress

## Metrics for Success

### Quantitative
- Issues completed per week
- Time to completion per issue type
- Blocker frequency
- PR merge rate

### Qualitative
- Research quality
- Documentation completeness
- Code coverage
- Reproducibility

## Integration with CI/CD

### Automated Checks
- Issue templates validation
- Label consistency
- Milestone progress
- Dependency tracking

### Research Artifacts
- Link issues to:
  - Paper sections
  - Data files
  - Analysis notebooks
  - Benchmarks

## Tips for Researchers

1. **Be Specific**: Clear issue titles and descriptions
2. **Stay Organized**: Use labels consistently
3. **Document Everything**: Research is about reproducibility
4. **Collaborate**: Tag others for input
5. **Iterate**: Research is exploratory - update issues as you learn

## Current Status

### Active Phase: Phase 1 - Literature Review
- [x] Issue templates created
- [x] Labels configured
- [x] Milestones set
- [x] Initial issues created
- [ ] Project board configured (manual setup required)

### Next Actions
1. Complete literature review issues
2. Begin Phase 2 planning
3. Set up CI/CD integration
4. Recruit collaborators

---

**Last Updated**: January 2025  
**Maintainer**: Research Team  
**Questions**: Create an issue with `help-wanted` label