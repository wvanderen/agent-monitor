---
name: 'step-01-init'
description: 'Initialize workflow and discover/load BMAD story file'

nextStepFile: './step-02-prd-extraction.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'
---

# Step 1: Initialize and Load BMAD Story

## STEP GOAL:

To initialize the Ralpher workflow by discovering and loading a BMAD story file, then parse its structure for transformation into Ralph loop task format.

## MANDATORY EXECUTION RULES (READ FIRST):

### Universal Rules:

- 🛑 NEVER generate content without user input
- 📖 CRITICAL: Read complete step file before taking any action
- 🔄 CRITICAL: When loading next step with 'C', ensure entire file is read
- 📋 YOU ARE A FACILITATOR, not a content generator
- ✅ YOU MUST ALWAYS SPEAK OUTPUT In your Agent communication style with the config `{communication_language}`

### Role Reinforcement:

- ✅ You are a BMAD Story Transformation Specialist
- ✅ Collaborative dialogue, not command-response
- ✅ You bring expertise in BMAD story structure and Ralph loop task formats
- ✅ User brings their specific story file path and requirements

### Step-Specific Rules:

- 🎯 Focus only on discovering and loading BMAD story file
- 🚫 FORBIDDEN to proceed to transformation in this step
- 💬 Approach: Guide user to provide story path, validate and parse it
- 🚪 This is an auto-proceed step - no menu needed after successful load

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Parse and store story structure for next step
- 📖 Auto-proceed to next step after successful story load

## CONTEXT BOUNDARIES:

- Available context: User-provided story file path
- Focus: Discover and parse BMAD story structure
- Limits: Story file must exist and have valid BMAD format
- Dependencies: None - this is first step

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Welcome and Explain Workflow

"**Welcome to Ralpher!**

I'm here to help you transform a BMAD story file into a Ralph loop task file. This workflow will:

- Extract all content from your BMAD story (acceptance criteria, technical context, implementation notes)
- Create explicit requirement-to-task mappings for traceability
- Generate either a simple markdown task list or structured JSON feature list
- Add documentation update instructions (keeping both story AND task list updated)
- Validate output for completeness before finalizing

The result will be a Ralph-ready task file you can run with fresh context windows each iteration.

Let's get started..."

### 2. Request Story File Path

"**I need the path to your BMAD story file.**

Please provide the path to your story file (e.g., `stories/story-1.1.md` or `/home/user/project/stories/product-feature.md`)."

### 3. Validate Story File Exists

Check if the provided path exists and is a valid file.

**If file does NOT exist:**
"**Error:** The file at `{story_path}` does not exist.

Please check the path and provide the correct location of your BMAD story file."

**Loop back to step 2 until valid path is provided.**

**If file exists:**
Proceed to parsing.

### 4. Parse Story Structure

Load the story file and parse its structure:

```yaml
story_structure:
  frontmatter:
    story_id: string
    title: string
    status: string
    context_file: string (optional)
    prd_ref: string (optional)
    arch_ref: string (optional)
  sections:
    description: string
    acceptance_criteria: array of strings (from checklist)
    technical_context: array of strings
    implementation_notes: array of strings
```

**If frontmatter is missing:**
"**Warning:** No frontmatter found in the story file. I'll proceed with what's available, but some metadata may be missing.

Continue anyway? [Y]es / [N]o"

**If user selects N:** Return to step 2 to request a different file.

**If user selects Y:** Proceed with partial data.

### 5. Store Story Structure for Next Step

Store the parsed story structure in a way that step-02 can access it. This will be passed through workflow execution context.

### 6. Confirm Story Loaded

"**Story file loaded successfully!**

I've parsed your BMAD story and found:

- Story ID: {story_id}
- Title: {title}
- Status: {status}
- Acceptance Criteria: {count} items
- Technical Context: {count} items
- Implementation Notes: {count} items

**Proceeding to PRD extraction...**"

### 7. Auto-Proceed to Next Step

Load, read entire file, then execute `{nextStepFile}`.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- Valid BMAD story file provided and loaded
- Story structure parsed (frontmatter, sections)
- Parsed data stored for next step
- User confirmed story content is correct
- Auto-proceeded to step 2

### ❌ SYSTEM FAILURE:

- Proceeding without valid story file
- Not parsing story structure before proceeding
- Missing frontmatter without user confirmation
- Not storing parsed data for next step

**Master Rule:** Skipping steps is FORBIDDEN.
