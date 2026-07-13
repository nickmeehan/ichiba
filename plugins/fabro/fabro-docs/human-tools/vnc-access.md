> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# VNC Access

> Access graphical desktop environments in sandboxes via VNC

<Warning>
  VNC access is **coming soon** and is not yet available. This page describes the planned feature.
</Warning>

VNC (Virtual Network Computing) provides a graphical desktop environment inside sandboxes, accessible directly from your browser. This enables interaction with GUI applications, visual debugging, and observation of agent-driven desktop automation.

## Use cases

* **GUI application testing** — interact with desktop apps built or modified by an agent
* **Browser testing** — verify web applications in a full browser environment inside the sandbox
* **Visual debugging** — inspect graphical output, rendered documents, or UI state
* **Agent observation** — watch an AI agent perform automated desktop interactions

## How it works

Sandboxes support VNC through a set of pre-installed packages (Xvfb, xfce4, x11vnc, noVNC) that provide a headless desktop environment with browser-based access. When VNC is enabled:

1. Start a run with VNC enabled on a cloud sandbox
2. Open a browser-based VNC viewer to see the sandbox desktop
3. Interact with the desktop using mouse and keyboard — or watch an agent automate it

## Example workflow

VNC is useful when the agent needs to interact with a GUI application that can't be driven through a CLI alone. This workflow automates filling out a legacy internal web form that requires browser interaction:

<Frame>
  <img src="https://mintcdn.com/qltysoftware-21b56213/G7Im2lhV2VdE8zmz/images/vnc-access-workflow.svg?fit=max&auto=format&n=G7Im2lhV2VdE8zmz&q=85&s=6119976f60e1d7c4c32c70507ad0f341" alt="VNC access workflow: Start → Prepare Data → Fill Portal Form → Review Submission → Exit, with a Redo loop back to Fill Portal Form" width="897" height="59" data-path="images/vnc-access-workflow.svg" />
</Frame>

```dot theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph FillLegacyForm {
    graph [goal="Submit the quarterly compliance data through the internal portal"]

    start [shape=Mdiamond, label="Start"]
    exit  [shape=Msquare, label="Exit"]

    prepare [label="Prepare Data", prompt="Read the compliance data from data/quarterly-compliance.csv and format it for entry into the internal portal."]
    fill    [label="Fill Portal Form", prompt="Open Firefox, navigate to http://compliance.internal:8080, and fill out the quarterly submission form with the prepared data. Take a screenshot after each page."]
    review  [shape=hexagon, label="Review Submission"]

    start -> prepare -> fill -> review
    review -> exit [label="[A] Submit"]
    review -> fill [label="[R] Redo"]
}
```
