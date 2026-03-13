# Chapter 3 ABSMC Simulation Embedding Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate Chapter 3 ABSMC simulation figures from `BSMC_Sim.py`, embed them into the HTML presentation as viewport-safe simulation slides, and add the requested thesis reference.

**Architecture:** Reuse the existing simulation script as the single source of truth for figures. Add only the minimum export logic needed for deterministic PNG output, then split the Chapter 3 simulation area into multiple continuation slides so each slide stays within the viewport while matching the existing academic presentation structure.

**Tech Stack:** Python, NumPy, SciPy, Matplotlib, single-file HTML/CSS/JS presentation

---

### Task 1: Verify the current missing behavior

**Files:**
- Inspect: `/Users/xiakaiyang/Projects/BSMC_Sim.py`
- Inspect: `/Users/xiakaiyang/Desktop/quadrotor_control_presentation.html`

**Step 1: Run a failing check for figure availability**
Run a command that confirms the expected exported Chapter 3 figure PNGs do not yet exist.

**Step 2: Run a failing check for HTML embedding**
Run a command that confirms the current Chapter 3 simulation section does not yet contain embedded figure tags for Fig 5-1 to Fig 5-6.

### Task 2: Export simulation figures

**Files:**
- Modify: `/Users/xiakaiyang/Projects/BSMC_Sim.py`

**Step 1: Add minimal export logic**
Save each generated figure to a deterministic output directory without changing control or dynamics behavior.

**Step 2: Run the script**
Execute the script and verify that all required PNGs are written.

### Task 3: Embed figures into the presentation

**Files:**
- Modify: `/Users/xiakaiyang/Desktop/quadrotor_control_presentation.html`

**Step 1: Keep the summary simulation slide**
Preserve the current setup/parameter overview as the first simulation page.

**Step 2: Add continuation slides**
Add additional Chapter 3 simulation slides that embed the exported figures in a two-up academic layout with short figure captions.

**Step 3: Add the thesis reference**
Add the requested Harbin University of Science and Technology thesis reference to the simulation section.

### Task 4: Verify rendering

**Files:**
- Verify: `/Users/xiakaiyang/Desktop/quadrotor_control_presentation.html`

**Step 1: Start a local static server**
Serve the Desktop directory locally for browser verification.

**Step 2: Open and inspect the presentation**
Confirm the new simulation slides render, the images load, and the slide content stays within the viewport.

**Step 3: Check console errors**
Confirm there are no new browser errors introduced by the changes.
