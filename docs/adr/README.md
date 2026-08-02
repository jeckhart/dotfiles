# Architecture Decision Records

Decisions that shape this repo but aren't obvious from reading the code — why a design
was chosen, what alternatives lost, what would have to change to revisit it.

## Format

One file per decision: `NNNN-kebab-title.md`, numbered sequentially, never reused. Each
file has four sections:

- **Status** — Proposed / Accepted / Superseded by ADR-NNNN.
- **Context** — the forcing problem: what broke, what kept coming up, what constraint
  drove this.
- **Decision** — what we're doing, stated plainly.
- **Consequences** — what this makes easy, what it makes harder, and any exceptions to
  the rule that already exist and are staying.

Decisions aren't edited in place once Accepted — if one changes, write a new ADR and mark
the old one Superseded. This keeps the history honest: you can see what we used to think
and why we changed our minds.

## Before this convention existed

Most existing decisions in this repo live as inline rationale in `CLAUDE.md` and
`docs/radicle.md` rather than as ADRs — that's fine, and there's no project to
retroactively convert them. Write one here going forward when a decision is non-obvious
enough that a future reader (human or agent) would otherwise have to reverse-engineer it
from a diff or a bug report.
