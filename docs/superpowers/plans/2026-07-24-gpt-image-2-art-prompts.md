# GPT Image 2 Art Prompts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all 10 art prompts with precise GPT Image 2 scene contracts while preserving reproducible JSON and manifest generation.

**Architecture:** The prompt source remains `tools/generate_content.py`; generated case JSON and `assets/art_manifest.md` remain outputs. Tests validate structure, length, unique style suffixes, required literal text, and the left/right continuity relationships central to case 02.

**Tech Stack:** Python 3 content generator, strict JSON, Godot 4 GDScript headless tests.

---

### Task 1: Add prompt contract regression tests

**Files:**
- Modify: `tests/test_mvp_content.gd`

- [ ] Add assertions that collect all `artAssets` prompts from the three MVP cases and require exactly 10 unique asset IDs.
- [ ] Require each prompt to be at least 700 characters and contain `Purpose and medium:`, `Camera and composition:`, `Scene and required details:`, `Required readable text:`, `Continuity:`, `Lighting and image defects:`, `Do not include:`, and `Output requirements:`.
- [ ] Require the applicable shared style suffix exactly once in each prompt.
- [ ] Require `MIRROR-17`, `N17`, `DF-2`, `left side of the door`, `right side of the door`, and the frame-39 foreground/reflection relationship in the corresponding assets.
- [ ] Run `powershell -ExecutionPolicy Bypass -File .\tools\test.ps1` and confirm the new assertions fail against the old prompts.

### Task 2: Introduce a reusable prompt composer

**Files:**
- Modify: `tools/generate_content.py`

- [ ] Add a `compose_art_prompt()` helper accepting purpose, composition, scene details, readable text, continuity, lighting, exclusions, output requirements, and a horror flag.
- [ ] Make the helper emit the eight labeled English sections and append exactly one appropriate shared style suffix.
- [ ] Change `write_art_manifest()` to output the completed prompt without appending another suffix.

### Task 3: Rewrite all 10 scene contracts

**Files:**
- Modify: `tools/generate_content.py`

- [ ] Replace every short `artAssets[].prompt` value with a `compose_art_prompt()` call containing asset-specific camera, spatial, textual, continuity, defect, and negative constraints from the approved design.
- [ ] Make `art_frame39` explicitly instruct the user to upload `art_raven_stream_base.png` as the image reference and preserve every object and pixel-level camera relationship except the mirror reflection's head direction.
- [ ] Keep critical literal text limited to `MIRROR-17`, `N17`, `DF-2`, `2023`, and `棚 B` where required; forbid unrelated readable text and pseudo-interface overlays.

### Task 4: Regenerate and verify outputs

**Files:**
- Regenerate: `data/cases/prologue.json`
- Regenerate: `data/cases/case_01_gate.json`
- Regenerate: `data/cases/case_02_dead_streamer.json`
- Regenerate: `assets/art_manifest.md`

- [ ] Run `python .\tools\generate_content.py`.
- [ ] Inspect `assets/art_manifest.md` to ensure prompts are complete, non-duplicated, and preserve table formatting.
- [ ] Run `powershell -ExecutionPolicy Bypass -File .\tools\test.ps1`; expected result is all assertions and smoke tests passing.
- [ ] Run the project's forbidden-placeholder scan outside the validator's forbidden-token declaration.

The workspace is not a Git repository, so this plan has no commit steps.
