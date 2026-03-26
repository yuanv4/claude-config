---
name: codex
description: Delegate tasks to OpenAI Codex expert agents (GPT) for architecture analysis, plan review, scope analysis, code review, security audit, or implementation. Use when the user says "codex", "ask GPT", "use codex to review/implement", or when semantic triggers match (architecture decisions, plan validation, code review, security concerns).
---

# Codex Expert Delegation

> Adapted from [claude-delegator](https://github.com/jarrodwatts/claude-delegator) by [@jarrodwatts](https://github.com/jarrodwatts)

Delegate structured tasks to OpenAI Codex CLI expert agents and synthesize their responses.

## Available Experts

| Expert | Specialty | Prompt File |
|--------|-----------|-------------|
| **Architect** | System design, tradeoffs, complex debugging | `experts/architect.md` |
| **Plan Reviewer** | Plan validation before execution | `experts/plan-reviewer.md` |
| **Scope Analyst** | Pre-planning, catching ambiguities | `experts/scope-analyst.md` |
| **Code Reviewer** | Code quality, bugs, security issues | `experts/code-reviewer.md` |
| **Security Analyst** | Vulnerabilities, threat modeling | `experts/security-analyst.md` |

## Trigger Detection

### Explicit Triggers (highest priority)

| User says | Expert |
|-----------|--------|
| "ask GPT", "use codex", "codex review", "codex implement" | Route based on context |
| "review this architecture", "how should I structure" | Architect |
| "review this plan", "validate before I start" | Plan Reviewer |
| "analyze the scope", "what am I missing" | Scope Analyst |
| "review this code", "find issues in" | Code Reviewer |
| "security review", "is this secure", "harden this" | Security Analyst |

### Semantic Triggers

| Pattern | Expert |
|---------|--------|
| Architecture/design questions, tradeoff analysis | Architect |
| After 2+ failed fix attempts (fresh perspective) | Architect |
| Before starting significant work, plan validation | Plan Reviewer |
| Vague/ambiguous requirements, "before we start" | Scope Analyst |
| "what's wrong with", after implementing features | Code Reviewer |
| Handling sensitive data, auth changes, new API endpoints | Security Analyst |

### When NOT to Delegate

- Simple questions you can answer directly
- First attempt at any fix (try yourself first)
- Trivial decisions (variable names, formatting)
- Research tasks (use WebSearch or other tools)

---

## Delegation Flow

### Step 1: Identify Expert

Match the task to the appropriate expert from the trigger tables above.

### Step 2: Read Expert Prompt

**CRITICAL**: Read the expert's prompt file relative to this skill's directory:

```
Read experts/[expert-name].md
```

This content will be prepended to the delegation prompt as the expert's system instructions.

### Step 3: Determine Mode

| Task Type | Mode | Sandbox |
|-----------|------|---------|
| Analysis, review, recommendations | Advisory | `read-only` |
| Make changes, fix issues, implement | Implementation | `workspace-write` |

The mode is determined by the **task**, not the expert. Any expert can advise or implement.

### Step 4: Notify User

Always inform the user before delegating:
```
Delegating to [Expert Name]: [brief task summary]
```

### Step 5: Build Delegation Prompt

Combine the expert prompt (from Step 2) with a task prompt that follows the **7-section format**:

```
[Expert prompt content from experts/*.md]

---

TASK: [One sentence -- atomic, specific goal]

EXPECTED OUTCOME: [What success looks like]

CONTEXT:
- Current state: [what exists now]
- Relevant code: [paths or snippets]
- Background: [why this is needed]

CONSTRAINTS:
- Technical: [versions, dependencies]
- Patterns: [existing conventions to follow]
- Limitations: [what cannot change]

MUST DO:
- [Requirement 1]
- [Requirement 2]

MUST NOT DO:
- [Forbidden action 1]
- [Forbidden action 2]

OUTPUT FORMAT:
- [How to structure response]
```

Include FULL context -- relevant code, file paths, previous attempts, error messages. One well-structured delegation beats multiple vague ones.

### Step 6: Call Codex

Run via `codex exec` CLI:

```bash
codex exec --skip-git-repo-check \
  --sandbox <read-only|workspace-write> \
  --full-auto \
  -C "<working directory>" \
  "<combined prompt>" 2>/dev/null
```

Rules:
- Always use `--skip-git-repo-check`
- Always append `2>/dev/null` to suppress thinking tokens (stderr)
- For `workspace-write`, always include `--full-auto`
- For `read-only`, `--full-auto` is optional

### Step 7: Synthesize Response

1. **Never show raw output** -- interpret and summarize for the user
2. **Extract key insights** -- recommendations, issues, changes made
3. **Apply your own judgment** -- experts can be wrong; evaluate critically
4. **For implementation mode** -- verify the changes actually work

---

## Multi-Turn Sessions (Resume)

Codex CLI supports resuming the last session to continue with full context preservation.

### When to Use Resume

- Chained implementation steps (implement, then test, then refine)
- Retry after failure (expert remembers what was tried)
- Iterative refinement (review, revise, re-review)

### Resume Syntax

```bash
echo "<follow-up prompt>" | codex exec --skip-git-repo-check resume --last 2>/dev/null
```

- Do **not** add config flags when resuming -- the session inherits them from the original
- All flags must go between `exec` and `resume`

### Retry Flow

```
Attempt 1 (codex exec) -> Verify -> [Fail]
     |
Attempt 2 (resume with error details) -> Verify -> [Fail]
     |
Attempt 3 (resume with full error history) -> Verify -> [Fail]
     |
Escalate to user
```

---

## CLI Reference

### New Session

```bash
codex exec --skip-git-repo-check \
  -m <model> \
  --config model_reasoning_effort="<xhigh|high|medium|low>" \
  --sandbox <read-only|workspace-write|danger-full-access> \
  --full-auto \
  -C "<directory>" \
  "<prompt>" 2>/dev/null
```

### Quick Reference

| Use case | Command |
|----------|---------|
| Read-only analysis | `codex exec --skip-git-repo-check --sandbox read-only "<prompt>" 2>/dev/null` |
| Write changes | `codex exec --skip-git-repo-check --sandbox workspace-write --full-auto "<prompt>" 2>/dev/null` |
| Full access | `codex exec --skip-git-repo-check --sandbox danger-full-access --full-auto "<prompt>" 2>/dev/null` |
| Resume session | `echo "<prompt>" \| codex exec --skip-git-repo-check resume --last 2>/dev/null` |

### Available Flags

| Flag | Description |
|------|-------------|
| `-m, --model <MODEL>` | Model to use (e.g. `gpt-5.4`, `gpt-5.3-codex`) |
| `--config key="value"` | Override config.toml settings per-call |
| `--sandbox <mode>` | `read-only`, `workspace-write`, `danger-full-access` |
| `--full-auto` | Auto-approve tool calls (required for write modes) |
| `-C, --cd <DIR>` | Working directory |
| `--skip-git-repo-check` | Skip git repo validation (always use) |

---

## Expert-Specific Prompt Templates

### Architect

```
TASK: [Analyze/Design/Implement] [specific system/component] for [goal].
EXPECTED OUTCOME: [Clear recommendation OR working implementation]
CONTEXT:
- Current architecture: [description]
- Relevant code: [file paths or snippets]
- Problem/Goal: [what needs to be solved]
CONSTRAINTS:
- Must work with [existing systems]
- Cannot change [protected components]
MUST DO:
- [Specific requirement]
- Provide effort estimate (Quick/Short/Medium/Large)
MUST NOT DO:
- Over-engineer for hypothetical future needs
- Introduce new dependencies without justification
OUTPUT FORMAT:
Advisory: Bottom line -> Action plan -> Effort estimate
Implementation: Summary -> Files modified -> Verification
```

### Plan Reviewer

```
TASK: Review [plan name/description] for completeness and clarity.
EXPECTED OUTCOME: APPROVE/REJECT verdict with specific feedback.
CONTEXT:
- Plan to review: [plan content]
- Goals: [what the plan achieves]
- Constraints: [timeline, resources, technical limits]
MUST DO:
- Evaluate all 4 criteria (Clarity, Verifiability, Completeness, Big Picture)
- Simulate actually doing the work to find gaps
- Provide specific improvements if rejecting
MUST NOT DO:
- Rubber-stamp without real analysis
- Provide vague feedback
- Approve plans with critical gaps
OUTPUT FORMAT:
[APPROVE / REJECT]
Justification: [explanation]
Summary: [4-criteria assessment]
[If REJECT: Top 3-5 improvements needed]
```

### Code Reviewer

```
TASK: [Review / Review and fix] [code/PR/file] for [focus areas].
EXPECTED OUTCOME: [Issue list with verdict OR fixed code]
CONTEXT:
- Code to review: [file paths or snippets]
- Purpose: [what this code does]
- Recent changes: [what changed]
MUST DO:
- Prioritize: Correctness -> Security -> Performance -> Maintainability
- Focus on issues that matter, not style nitpicks
MUST NOT DO:
- Nitpick style (let formatters handle this)
- Flag theoretical concerns unlikely to matter
OUTPUT FORMAT:
Advisory: Summary -> Critical issues -> Recommendations -> Verdict
Implementation: Summary -> Issues fixed -> Files modified -> Verification
```

### Security Analyst

```
TASK: [Analyze / Harden] [system/code/endpoint] for security vulnerabilities.
EXPECTED OUTCOME: [Vulnerability report OR hardened code]
CONTEXT:
- Code/system to analyze: [file paths, architecture description]
- Assets at risk: [what's valuable]
- Threat model: [who might attack, if known]
MUST DO:
- Check OWASP Top 10 categories
- Consider authentication, authorization, input validation
- Provide practical remediation, not theoretical concerns
MUST NOT DO:
- Flag low-risk theoretical issues
- Provide vague "be more secure" advice
OUTPUT FORMAT:
Advisory: Threat summary -> Vulnerabilities -> Recommendations -> Risk rating
Implementation: Summary -> Vulnerabilities fixed -> Files modified -> Verification
```

### Scope Analyst

```
TASK: Analyze [request/feature] before planning begins.
EXPECTED OUTCOME: Clear understanding of scope, risks, and questions to resolve.
CONTEXT:
- Request: [what was asked for]
- Current state: [what exists now]
- Known constraints: [technical, business, timeline]
MUST DO:
- Classify intent (Refactoring/Build/Mid-sized/Architecture/Bug Fix/Research)
- Identify hidden requirements and ambiguities
- Surface questions that need answers before proceeding
MUST NOT DO:
- Start planning (that comes after analysis)
- Make assumptions about unclear requirements
OUTPUT FORMAT:
Intent: [classification]
Findings: [key discoveries]
Questions: [what needs clarification]
Risks: [with mitigations]
Recommendation: [Proceed / Clarify First / Reconsider]
```

---

## Critical Evaluation of Codex Output

Codex is powered by OpenAI models. Treat it as a **colleague, not an authority**.

- **Trust your own knowledge** when confident. Push back if Codex is wrong.
- **Research disagreements** via WebSearch or docs before accepting claims.
- **Remember knowledge cutoffs** -- Codex may not know about recent changes.
- **Evaluate critically** -- especially model names, library versions, API changes.

### When Codex is Wrong

1. State your disagreement clearly to the user
2. Provide evidence (your knowledge, web search, docs)
3. Optionally resume the session to discuss:
   ```bash
   echo "This is Claude following up. I disagree with [X] because [evidence]. What's your take?" | codex exec --skip-git-repo-check resume --last 2>/dev/null
   ```
4. Let the user decide if there's genuine ambiguity

---

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Delegate trivial questions | Answer directly |
| Show raw expert output | Synthesize and interpret |
| Skip reading expert prompt file | ALWAYS read and inject into the prompt |
| Skip user notification | ALWAYS notify before delegating |
| Retry without error context | Include FULL history of what was tried |
| Assume expert remembers across sessions | Use `resume --last` for multi-turn; include full context for new sessions |
| Spam multiple vague delegations | One well-structured delegation with full context |
