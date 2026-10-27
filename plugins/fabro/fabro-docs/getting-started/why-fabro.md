> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Why Fabro?

> The problems Fabro solves for AI-assisted software teams

Fabro is the open source dark software factory for small teams of expert engineers. It replaces the prompt-wait-review loop with version-controlled workflow graphs that orchestrate AI agents, shell commands, and human decisions into repeatable, long-horizon coding processes.

## The problem

AI coding agents have transformed software engineering productivity, but the surrounding toolchain hasn't kept up:

* **Developers work for the agents.** The prompt-wait-review loop idles engineers while agents run, then demands constant babysitting to course-correct.
* **Unpredictable agents force oversight.** Non-deterministic guardrails create an explosion of failure modes. Engineers compensate by watching every step.
* **Verification is overwhelmed.** Agent throughput exceeds human review capacity. CI pipelines designed for pass/fail signals can't keep pace with the volume or nuance of AI-generated code.
* **Token costs are primed to explode.** ROI per token diverges wildly across tasks, models, and harnesses. Every unnecessary frontier token is one that can't be spent where it matters.
* **The continuous improvement loop broke.** Data is lost at every sub-process boundary. Organizations can't train LLMs the way they train people, and memory files make no guarantees.

![Fabro run detail view showing verifications for a pipeline event types change, including Traceability, Readability, Reliability, Code Coverage, and more](https://mintcdn.com/qltysoftware-21b56213/_yTKyxnEAApivGto/images/run-detail.png?fit=max\&auto=format\&n=_yTKyxnEAApivGto\&q=85\&s=cf8c007a1272e8a757804f8a671c0c5b)

## How Fabro solves this

Fabro gives you a deterministic harness around non-deterministic AI. You define **workflow graphs** in Graphviz files that specify exactly what happens, in what order, with which models, and where humans weigh in. Fabro handles orchestration, parallelism, model routing, verification, and observability.

> **Version-controlled workflows**
>
> Define workflows as code in Graphviz. Nodes are agents, shell commands, or human input gates. Fan out, loop, branch, and resume — all traceable and repeatable.

> **Multi-model orchestration**
>
> Route tasks to the right model using CSS-like stylesheets. Cross-critique with fresh eyes, delegate simple tasks to fast models, and fail over automatically when providers go down.

> **Human-in-the-loop**
>
> Steer while the agent runs, not after. Approval gates, interviews, and steering let you intervene at the right moments without waiting for a pull request.

> **Adaptive verification**
>
> Combine LLM-as-judge, test suites, third-party tools, and human review. Verifications act as an eval suite tailored to your organization, building confidence over time.

> **Observability**
>
> Every tool call, agent turn, and shell command is captured in a unified event stream. Query run data with SQL via DuckDB and inspect the full execution trail.

> **Open source**
>
> Licensed under MIT. Written in Rust with minimal dependencies. Runs on a single node with no databases to set up.

![Fabro workflow diagram for Fix Build showing stages from Start through Analyze Build Errors, Diagnose Root Cause, Validate Build, and Review Changes to Exit](https://mintcdn.com/qltysoftware-21b56213/_yTKyxnEAApivGto/images/workflow-example.png?fit=max\&auto=format\&n=_yTKyxnEAApivGto\&q=85\&s=03cdb95029ca87b4f7349eee50fe7b4f)

## What a workflow looks like

Workflows are defined in Graphviz, a simple graph description language. Here's a plan-approve-implement workflow and its Graphviz source:

![Plan-Implement workflow graph](https://mintcdn.com/qltysoftware-21b56213/G7Im2lhV2VdE8zmz/images/plan-implement-workflow.svg?fit=max\&auto=format\&n=G7Im2lhV2VdE8zmz\&q=85\&s=d31c0e94a013abdd4fb2d2d2fd3680c6)

```dot title="plan-implement.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph PlanImplement {
    graph [goal="Plan, approve, implement, and simplify a change"]

    start [shape=Mdiamond, label="Start"]
    exit  [shape=Msquare, label="Exit"]

    plan      [label="Plan", prompt="Analyze the goal and codebase. Write a step-by-step plan.", reasoning_effort="high"]
    approve   [shape=hexagon, label="Approve Plan"]
    implement [label="Implement", prompt="Read plan.md and implement every step."]
    simplify  [label="Simplify", prompt="Review the changes for clarity and correctness."]

    start -> plan -> approve
    approve -> implement [label="[A] Approve"]
    approve -> plan      [label="[R] Revise"]
    implement -> simplify -> exit
}
```

This workflow plans a change, asks a human to approve it, implements the plan, and simplifies the result. If the human rejects the plan, the agent revises it. The entire process is version-controlled, repeatable, and resumable.

## Next steps

> **[Quick Start](https://docs.fabro.sh/getting-started/quick-start.md)**
>
> Install Fabro and run your first workflow in minutes.


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.