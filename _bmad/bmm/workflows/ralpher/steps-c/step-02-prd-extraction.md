---
name: 'step-02-prd-extraction'
description: 'Extract story content and create Ralph PRD format with explicit requirement-to-task mappings'

nextStepFile: './step-03-complexity-assessment.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'

advancedElicitationTask: '{project-root}/_bmad/core/workflows/advanced-elicitation/workflow.xml'
partyModeWorkflow: '{project-root}/_bmad/core/workflows/party-mode/workflow.md'
---

# Step 2: PRD Extraction

## STEP GOAL:

To extract content from the loaded BMAD story and create a Ralph PRD format with explicit requirement-to-task mappings for traceability.

## MANDATORY EXECUTION RULES (READ FIRST):

### Universal Rules:

- 🛑 NEVER generate content without user input
- 📖 CRITICAL: Read complete step file before taking any action
- 🔄 CRITICAL: When loading next step with 'C', ensure entire file is read
- 📋 YOU ARE A FACILITATOR, not a content generator
- ✅ YOU MUST ALWAYS SPEAK OUTPUT In your Agent communication style with the config `{communication_language}`

### Role Reinforcement:

- ✅ You are a BMAD Story Transformation Specialist
- ✅ We engage in collaborative dialogue, not command-response
- ✅ You bring expertise in Ralph PRD format and requirement-to-task mapping
- ✅ User brings their specific story content from step-01
- ✅ Together we create a transformation-ready Ralph PRD

### Step-Specific Rules:

- 🎯 Focus on creating Ralph PRD format with requirement-to-task mappings
- 🚫 FORBIDDEN to generate actual Ralph task file yet (that's step-04)
- 💬 Collaboratively refine the PRD structure and mappings
- 🎯 Use Advanced Elicitation and Party Mode for quality enhancement

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Create and store Ralph PRD with mappings for next steps
- 📖 Update frontmatter stepsCompleted when proceeding to next step

## CONTEXT BOUNDARIES:

- Available context: Parsed BMAD story structure from step-01 (story_id, title, description, acceptance_criteria, technical_context, implementation_notes)
- Focus: Transform story content into Ralph PRD format with explicit mappings
- Limits: Build PRD only, don't generate final task file yet
- Dependencies: Step-01 must have successfully loaded and parsed story structure

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Extract Story Content

From the parsed story structure from step-01, extract:

**Story Metadata:**

- story_id
- title
- status
- description

**Story Content:**

- Acceptance criteria (array of items)
- Technical context (array of items)
- Implementation notes (array of items)

### 2. Create Ralph PRD Structure

Build the Ralph PRD format with these sections:

```markdown
# Task: {title}

## Description

{description from story}

## Requirements

{Transformed acceptance criteria into numbered requirements}

## Constraints

{Combine technical context + implementation notes}

## Acceptance Criteria

{All acceptance criteria from story, numbered}

## Requirement-to-Task Mappings

{Create explicit mappings for traceability}

## Documentation Update Instructions

{Instructions for Ralph agents to keep both story AND task list updated}

## Completion Instructions

{Standard Ralph loop completion instructions}
```

### 3. Transform Content to Ralph Format

**Transform Description:**
Use the story description directly as the Ralph task description.

**Transform Requirements:**
Convert BMAD story acceptance criteria (checkbox format) into numbered Ralph requirements.

Example:

- BMAD: "- [ ] Category list displays on left sidebar"
- Ralph: "1. Category list displays on left sidebar"

**Transform Constraints:**
Combine technical context and implementation notes into Ralph constraints section:

- List all technical context items
- List all implementation notes as constraints
- Format as prescriptive requirements (Ralph expects clear constraints)

**Create Requirement-to-Task Mappings:**

For each acceptance criterion from the story, create an explicit mapping:

```markdown
## Requirement-to-Task Mappings

| Requirement ID | Description                            | Mapped To Task                       |
| -------------- | -------------------------------------- | ------------------------------------ |
| AC-1           | Category list displays on left sidebar | Task 1: Implement sidebar navigation |
| AC-2           | Clicking category filters product grid | Task 2: Add category filtering logic |
```

This mapping serves two purposes:

1. **Initial validation:** Ensures all story requirements are captured
2. **Comprehensive review:** Enables BMAD code review workflow to trace implementation back to original story

### 4. Add Documentation Update Instructions

Create clear instructions for Ralph agents:

```markdown
## Documentation Update Instructions

**Ralph agents must keep both the original BMAD story AND this task list updated:**

1. **Update Story:** When implementing acceptance criteria, update the corresponding checkbox in the original BMAD story file
2. **Update Task List:** Mark tasks as complete in this task list as implementation progresses
3. **Add Vital Documentation:** If new technical decisions, API endpoints, or architectural patterns emerge, document them in both:
   - Original story file (in Technical Context or Implementation Notes sections)
   - This task list (as new constraints or notes)

**Why this matters:**

- Enables comprehensive BMAD code review workflow to trace everything back to requirements
- Preserves traceability across the development lifecycle
- Prevents information loss between Ralph iterations and code review
```

### 5. Add Completion Instructions

Standard Ralph loop completion instructions:

```markdown
## Completion Instructions

You are in a Ralph loop. Work iteratively until ALL acceptance criteria are met and verified.

After each iteration:

1. Implement requirements in order
2. Run tests and fix failures
3. Update both the original BMAD story file AND this task list with progress
4. Verify mobile responsiveness (if applicable)

When genuinely complete and all acceptance criteria are satisfied:

- Mark all requirements as satisfied in this task list
- Update the original BMAD story file with all checkboxes marked complete

Output exactly: <promise>COMPLETE</promise>

**DO NOT** output the promise until all acceptance criteria are truly satisfied.
```

### 6. Review and Refine PRD

Present the complete Ralph PRD draft to user:

"**Ralph PRD Draft Created**

I've created the Ralph PRD format from your BMAD story. Here's what I've extracted:

**Story:** {title} ({story_id})

**PRD Structure:**

- Description: [first 2-3 lines]
- Requirements: {count} items extracted
- Constraints: {count} technical context + {count} implementation notes
- Requirement-to-Task Mappings: {count} explicit mappings created
- Documentation Update Instructions: Added
- Completion Instructions: Added

**Traceability:**

- All {count} acceptance criteria have explicit task mappings
- Documentation update instructions will keep story AND task list synchronized
- Ready for comprehensive BMAD code review workflow

**Would you like to:**

- Review the full PRD content?
- Use Advanced Elicitation to explore alternative approaches?
- Use Party Mode for collaborative refinement?
- Proceed to complexity assessment?"

### 7. Present MENU OPTIONS

Display: **PRD Complete - Select an Option:** [R] Review Full PRD [A] Advanced Elicitation [P] Party Mode [C] Continue to Complexity Assessment

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- ONLY proceed to next step when user selects 'C'
- After other menu items execution, return to this menu

#### Menu Handling Logic:

- IF R: Display full Ralph PRD content, then redisplay menu
- IF A: Execute {advancedElicitationTask}, and when finished redisplay menu
- IF P: Execute {partyModeWorkflow}, and when finished redisplay menu
- IF C: Save PRD to workflow state for next steps, update frontmatter stepsCompleted, then load, read entire file, then execute {nextStepFile}
- IF Any other comments or queries: help user, then [Redisplay Menu Options](#7-present-menu-options)

### 8. Store PRD for Next Steps

Save the Ralph PRD content in workflow execution context so step-03 and step-04 can access it.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- Ralph PRD structure created from BMAD story content
- All acceptance criteria extracted and transformed into Ralph requirements
- Technical context and implementation notes combined into constraints
- Explicit requirement-to-task mappings created for traceability ({count} mappings)
- Documentation update instructions added (story + task list synchronization)
- Completion instructions added with proper promise format
- PRD stored for next steps
- User confirmed PRD content is correct

### ❌ SYSTEM FAILURE:

- Skipping transformation of story content
- Not creating explicit requirement-to-task mappings
- Missing documentation update instructions
- Not including completion instructions
- Proceeding without user confirmation

**Master Rule:** Skipping steps is FORBIDDEN.
