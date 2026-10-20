---
name: plan-to-dag
description: Convert an approved implementation plan into an orchestration task graph.
---

# Plan to DAG

Convert the approved plan into tasks.

For each task, give an ID, title, prompt, dependencies, acceptance criteria, and verification command.

Use `orchestrator_start` with the full task graph. Do not approve the run until the user approves the graph.
