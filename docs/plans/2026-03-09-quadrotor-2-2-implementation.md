# Quadrotor 2.2 Slide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure slide 2.2 in the quadrotor presentation so the cascade PID architecture is easier to explain during a live talk.

**Architecture:** Replace the current JS-generated hover diagram with a static teaching-oriented diagram. The new slide should foreground the main signal chain, make the `z`-axis thrust branch explicit, and keep detailed per-loop discussion deferred to slide 2.3.

**Tech Stack:** Single-file HTML presentation with inline CSS/JS.

---

### Task 1: Replace the interactive 2.2 architecture slide with a teaching-oriented layout

**Files:**
- Modify: `/Users/xiakaiyang/Desktop/quadrotor_presentation/full_presentation.html`
- Reference: `/Users/xiakaiyang/Documents/New project/docs/plans/2026-03-09-quadrotor-2-2-design.md`

**Step 1: Confirm the current failure mode**

Read the existing `2.2 四级串级PID控制架构` section and verify that:
- the main explanation depends on hover interactions,
- the signal flow order is not obvious at first glance,
- the bottom notes emphasize advantages rather than speaking order.

**Step 2: Write the minimal replacement structure**

Replace the dynamic container, inline style block, and inline script for slide `data-index="15"` with:
- one short lead sentence,
- one static diagram that shows the numbered main chain,
- one colored `z`-axis branch into the mixer,
- two compact explanation cards for speaking points.

**Step 3: Keep the slide scoped and non-redundant**

Ensure the new slide:
- does not repeat the full table content from `2.3`,
- keeps each block to a single output-oriented sentence,
- uses unique class names so the CSS does not spill into other slides.

**Step 4: Verify the slide visually**

Open the local HTML file in a browser and check slide 2.2 at presentation size. Confirm that:
- the reading order is obvious without hover,
- the `z`-axis branch is clearly separated from the `xy` attitude path,
- the slide fits without awkward overflow.

**Step 5: Record status**

Report what changed, where the design doc and implementation plan were saved, and whether any follow-up polishing remains.
