---
name: codex
description: Route tasks to Codex specialist sub-agents for architecture analysis, plan review, scope analysis, code review, security audit, or implementation. Use when the user says "codex", "ask GPT", "use codex to review/implement", or when semantic triggers match.
---

# Codex Delegation Router

> Adapted from [claude-delegator](https://github.com/jarrodwatts/claude-delegator) by [@jarrodwatts](https://github.com/jarrodwatts)

Use this skill as the **entrypoint** for Codex delegation. The skill decides whether delegation is appropriate, selects the right specialist sub-agent, reads the specialist prompt from this skill's own `agents/` directory, builds the task packet, runs Codex CLI, and synthesizes the result.

Keep this skill self-contained:

- Store the canonical specialist prompts in `skills/codex/agents/`
- Resolve those prompt files relative to this `SKILL.md`
- Use Codex CLI so the delegated worker runs on a Codex model

## Available Sub-Agents

| Sub-agent | Specialty | Prompt File |
|-----------|-----------|-------------|
| **Architect** | System design, tradeoffs, complex debugging | `agents/architect.md` |
| **Plan Reviewer** | Plan validation before execution | `agents/plan-reviewer.md` |
| **Scope Analyst** | Pre-planning, catching ambiguities | `agents/scope-analyst.md` |
| **Code Reviewer** | Code quality, bugs, security issues | `agents/code-reviewer.md` |
| **Security Analyst** | Vulnerabilities, threat modeling | `agents/security-analyst.md` |

## Responsibilities Split

### This Skill Owns

- Trigger detection
- Specialist selection
- Delegation prompt assembly
- Codex CLI invocation
- Retry and resume flow
- Result synthesis and verification

### Sub-Agents Own

- Domain-specific reasoning
- Role-specific response style
- Review or implementation behavior for their specialty

## Trigger Detection

### Explicit Triggers

| User says | Route |
|-----------|-------|
| "ask GPT", "use codex", "codex review", "codex implement" | Route based on task context |
| "review this architecture", "how should I structure" | Architect |
| "review this plan", "validate before I start" | Plan Reviewer |
| "analyze the scope", "what am I missing" | Scope Analyst |
| "review this code", "find issues in" | Code Reviewer |
| "security review", "is this secure", "harden this" | Security Analyst |

### Semantic Triggers

| Pattern | Route |
|---------|-------|
| Architecture/design questions, tradeoff analysis | Architect |
| After 2+ failed fix attempts and you want a fresh perspective | Architect |
| Before significant work, validate the plan | Plan Reviewer |
| Requirements are vague or ambiguous | Scope Analyst |
| Post-implementation issue finding or review | Code Reviewer |
| Sensitive data, auth, permissions, or new API surface | Security Analyst |

### When NOT to Delegate

- Simple questions you can answer directly
- First attempt at a straightforward fix
- Trivial decisions such as naming or formatting
- Pure research tasks better served by docs or web search

## Routing Matrix

Use this table when the right specialist is not obvious:

| Situation | Default Route | Why |
|-----------|---------------|-----|
| "How should we structure this?" | Architect | Design and tradeoff driven |
| "Before we start, what are we missing?" | Scope Analyst | Clarify before planning |
| "Is this plan solid?" | Plan Reviewer | Validate execution readiness |
| "Review this change / PR / diff" | Code Reviewer | Correctness-first review |
| "Is this secure?" / auth / permissions / exposed endpoint | Security Analyst | Security-first threat model |
| "We tried 2+ fixes and still do not understand the system behavior" | Architect | Fresh systems-level diagnosis |
| "Implement the approved design" | Architect or domain owner from prior step | Preserve design continuity |
| "Fix issues found during review" | Same reviewer in Implementation Mode | Keeps context and accountability |

## Routing Boundaries

Choose the **Code Reviewer** when the primary goal is:

- correctness
- regressions
- maintainability
- performance
- broad review of a change

Choose the **Security Analyst** when the primary goal is:

- threat modeling
- authn/authz review
- secret handling
- input validation on untrusted boundaries
- attack surface reduction
- security hardening before release

If both are important, use this rule:

- Broad change review with some security relevance: start with Code Reviewer
- Security-sensitive feature where correctness also matters: start with Security Analyst
- High-risk changes touching auth, permissions, payments, PII, admin actions, or public endpoints: run both

## Multi-Agent Patterns

Default to a single specialist. Use multiple specialists only when each one answers a distinct question.

### Sequential Delegation

Use sequential delegation when one step produces the input for the next:

1. Scope Analyst -> clarify request and risks
2. Plan Reviewer -> validate the resulting plan
3. Architect -> design or implement the approved approach

Other good sequential patterns:

1. Code Reviewer -> identify issues
2. Security Analyst -> deepen security findings if the change is sensitive
3. Same reviewer in Implementation Mode -> apply targeted fixes

### Parallel Delegation

Use parallel delegation only when the questions are independent and the result from one is not required to ask the other.

Good candidates for parallel work:

- Code Reviewer + Security Analyst on a sensitive PR
- Architect + Security Analyst on a new external-facing design
- Scope Analyst + Architect when the request has both product ambiguity and major technical tradeoffs

Do not run in parallel when:

- the request is small enough for one specialist
- the second specialist depends on the first specialist's output
- you are likely to get duplicate feedback without a clear division of responsibility

### Parallel Task Framing

When delegating in parallel, give each sub-agent an explicit angle:

- Code Reviewer: correctness, regression risk, maintainability
- Security Analyst: attack surface, authz boundaries, input handling
- Architect: system shape, coupling, migration path
- Scope Analyst: ambiguity, missing requirements, hidden constraints
- Plan Reviewer: plan clarity, verification, missing references

In synthesis, merge overlapping findings and remove duplicates. Do not present the user with two separate unfiltered reports.

## Delegation Flow

### Step 1: Choose the Sub-Agent

Select the best specialist from the routing tables above.

Before choosing, answer these three questions:

1. Is the core uncertainty about requirements, design, review quality, or security?
2. Do I need one answer first before I can ask the next question?
3. Will a second specialist produce genuinely different signal?

If the answer to question 3 is "no", use a single specialist.

### Step 2: Read the Sub-Agent Prompt

Read the selected specialist prompt from this skill's local `agents/` directory.

- Treat the directory containing this `SKILL.md` as the base path
- Resolve the selected prompt file from the table above relative to this skill
- Do not rely on project-root-relative paths or external agent registries

Always inject the full specialist prompt into the Codex CLI request so the delegated worker uses the intended role behavior.

### Step 3: Determine Execution Mode

| Task Type | Mode | Sandbox |
|-----------|------|---------|
| Analysis, review, recommendations | Advisory | `read-only` |
| Make changes, fix issues, implement | Implementation | `workspace-write` |

Mode is determined by the task, not by the sub-agent.

### Step 4: Notify the User

Before delegating, tell the user:

```text
Delegating to [Sub-agent Name]: [brief task summary]
```

### Step 5: Build the Task Packet

Use this 7-section structure:

```text
[Sub-agent prompt content]

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

Include concrete file paths, previous attempts, errors, and any local conventions. One complete delegation is better than multiple vague ones.

### Step 6: Call Codex CLI

Use `codex exec` so the delegated worker runs on a Codex model.

Prefer passing the combined prompt through stdin. This is more robust than passing a large prompt as a positional argument, especially when the prompt begins with YAML frontmatter such as `---`.

```bash
printf '%s' "<combined prompt>" | codex exec --skip-git-repo-check \
  --sandbox <read-only|workspace-write> \
  --full-auto \
  --cd "<working directory>" 2>/dev/null
```

Rules:

- Always use `--skip-git-repo-check`
- Always append `2>/dev/null` to suppress thinking tokens
- Prefer stdin over positional prompt arguments for multi-line task packets
- For `workspace-write`, always include `--full-auto`
- For `read-only`, `--full-auto` is optional

### Step 7: Synthesize the Result

1. Never paste raw model output to the user
2. Extract the important findings, recommendations, or changes
3. Apply your own judgment and challenge weak conclusions
4. For implementation mode, verify the claimed changes
5. If multiple specialists were used, reconcile conflicts and produce one clear recommendation

## Resume and Retry

Use resume when the same delegated thread needs another iteration:

```bash
printf '%s' "<follow-up prompt>" | codex exec --skip-git-repo-check resume --last 2>/dev/null
```

Use it for:

- chained implementation
- retry after a failed verification
- iterative refinement on the same context

Retry flow:

```text
Attempt 1 -> Verify -> Fail
Attempt 2 via resume with concrete failure details -> Verify -> Fail
Attempt 3 via resume with full attempt history -> Verify -> Fail
Escalate to user
```

## Critical Evaluation

Treat Codex like a colleague, not an authority.

- Trust your own knowledge when you have strong evidence
- Verify disagreements with docs or web search when needed
- Be alert to stale assumptions about tools, APIs, or versions
- Push back on overconfident but weak recommendations

If a delegated result looks wrong, say so clearly, provide evidence, and optionally continue the same session with a corrective follow-up.

## Anti-Patterns

| Don't | Do |
|-------|-----|
| Delegate trivial questions | Answer directly |
| Keep specialist prompts outside the skill | Read the canonical prompt from this skill's `agents/` directory |
| Fire multiple specialists without distinct roles | Give each specialist a unique review angle |
| Show raw expert output | Synthesize and interpret |
| Skip user notification | Always notify before delegating |
| Retry without full error context | Include complete failure history |
| Assume context is preserved across new sessions | Use `resume --last` or resend context |
