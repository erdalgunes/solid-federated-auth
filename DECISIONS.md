# Design Decisions

## What We're NOT Doing (And Why)

### No CI/CD Yet
- **Why not**: No code to test yet, will add when needed
- **When**: After core implementation exists

### No Docker/Containers
- **Why not**: Adds complexity without current benefit
- **When**: If reproducibility becomes an issue

### No Pre-commit Hooks
- **Why not**: Friction during research phase
- **When**: When multiple contributors join

### No Build System (Make/etc)
- **Why not**: Simple scripts suffice for now
- **When**: When build steps become complex

### No Complex Package Manager
- **Why not**: Basic requirements.txt and package.json work fine
- **When**: If dependency conflicts arise

## What We ARE Doing

### GitHub Issues for Everything
- **Why**: Traceability and accountability for research

### Simple File Structure
- **Why**: Easy to navigate and understand

### Comprehensive Documentation
- **Why**: Academic rigor requires reproducibility

### Direct Commands
- **Why**: Clarity over abstraction

## Principle: Add Complexity Only When Pain Justifies It

Not when best practices suggest it, but when we actually need it.