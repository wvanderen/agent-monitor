---
name: 'step-04-md-generation'
description: 'Generate markdown task list with requirement-to-task mappings and documentation update instructions'

nextStepFile: './step-05-validation-loop.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'

advancedElicitationTask: '{project-root}/_bmad/core/workflows/advanced-elicitation/workflow.xml'
partyModeWorkflow: '{project-root}/_bmad/core/workflows/party-mode/workflow.md'
---

# Step 4: Markdown Task List Generation

## STEP GOAL:

To generate a simple markdown task list for Ralph loop, including requirement-to-task mappings and documentation update instructions.

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
- ✅ You bring expertise in Ralph task list format and markdown structure
- ✅ User brings their PRD content and complexity assessment

### Step-Specific Rules:

- 🎯 Focus on generating markdown task list format
- 🚫 FORBIDDEN to generate JSON format (that's step-04-json-generation)
- 💬 Embed requirement-to-task mappings from PRD
- 💬 Include documentation update instructions
- 🎯 Use Advanced Elicitation and Party Mode for quality enhancement
- ⚙️ Pattern 1 subprocess: Final validation grep for required patterns

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Generate markdown task list with embedded mappings
- ⚙️ Use subprocess for final validation (grep for required patterns)
- 💾 Store task list for next step
- 📖 Update frontmatter stepsCompleted when proceeding to next step

## CONTEXT BOUNDARIES:

- Available context: Ralph PRD from step-02, complexity assessment from step-03
- Focus: Generate markdown task list format with mappings
- Limits: Markdown format only, no JSON
- Dependencies: Steps 02 and 03 must have completed successfully

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Access PRD and Assessment

Load and review:

- Ralph PRD content from step-02 (requirements, constraints, mappings)
- Complexity assessment from step-03 (Simple/Moderate - using markdown)

### 2. Create Markdown Task List Structure

Generate markdown task list:

```markdown
# Ralph Task: {title from PRD}

## Description

{description from PRD}

## Requirements

{All requirements from PRD, numbered}

## Constraints

{All constraints from PRD}

## Requirement-to-Task Mappings

{Explicit mappings from PRD}

## Documentation Update Instructions

{Instructions for Ralph agents}

## Acceptance Criteria

{All acceptance criteria from PRD}

## Completion Instructions

{Ralph loop completion instructions}

## Completion Promise

<promise>COMPLETE</promise>
```

### 3. Embed Requirement-to-Task Mappings

Ensure all requirement-to-task mappings from PRD are included:

```markdown
## Requirement-to-Task Mappings

| Requirement ID | Description | Mapped To Task        |
| -------------- | ----------- | --------------------- |
| REQ-1          | {from PRD}  | Task 1: {mapped task} |
| REQ-2          | {from PRD}  | Task 2: {mapped task} |
```

This ensures:

- All story requirements are captured
- Comprehensive BMAD code review can trace implementation back to original story
- Ralph agents have clear task priorities

### 4. Include Documentation Update Instructions

Ensure documentation update instructions are clear:

```markdown
## Documentation Update Instructions

**Ralph agents must keep both the original BMAD story file AND this task list updated:**

1. **Update Story:** When completing a requirement, update the corresponding checkbox in the original BMAD story file
2. **Update Task List:** Mark tasks as complete in this task list as implementation progresses
3. **Add Vital Documentation:** If new technical decisions, API endpoints, or architectural patterns emerge, document them in:
   - Original story file (in Technical Context or Implementation Notes sections)
   - This task list (as new constraints or notes)
4. **Maintain Traceability:** Ensure all documentation changes reference the originating requirement

**Why this matters:**

- Enables comprehensive BMAD code review workflow to trace everything back to original story
- Preserves traceability across the Ralph loop and code review lifecycle
- Prevents information loss between Ralph iterations and code review
```

### 5. Include Completion Instructions

Standard Ralph loop instructions:

```markdown
## Completion Instructions

You are in a Ralph loop. Work iteratively until ALL acceptance criteria are met and verified.

After each iteration:

1. Implement requirements in order
2. Run tests and fix failures
3. Update both the original BMAD story file AND this task list with progress
4. Verify implementation against requirements

When genuinely complete and all acceptance criteria are satisfied:

- Mark all requirements as satisfied in this task list
- Update the original BMAD story file with all checkboxes marked complete

Output exactly: <promise>COMPLETE</promise>

**DO NOT** output the promise until all acceptance criteria are truly satisfied.
```

### 6. Validate Required Patterns with Subprocess

**Pattern 1 (Grep/Regex):** Final validation search for required patterns

Launch a subprocess that:

- Searches the generated markdown task list for required patterns
- Returns: structured list of patterns found/missing

**Required patterns to search for:**

- Completion promise format: `<promise>COMPLETE</promise>`
- Requirement-to-task mappings section exists
- Documentation update instructions section exists
- Acceptance criteria section exists

**Subprocess returns to parent:**

```json
{
  "patterns_found": [
    { "pattern": "completion_promise", "found": true, "line": 45 },
    { "pattern": "requirement_mappings", "found": true, "line": 30 }
  ],
  "patterns_missing": [
    { "pattern": "documentation_instructions", "found": false },
    { "pattern": "acceptance_criteria", "found": false }
  ],
  "summary": {
    "total_patterns_checked": 4,
    "patterns_found_count": 2,
    "patterns_missing_count": 2
  }
}
```

**Fallback:** If subprocess unavailable, perform grep checks in main thread.

### 7. Review Validation Results

Review subprocess validation results:

```markdown
**Pattern Validation Results:**

- ✅ Completion promise: Found at line 45
- ✅ Requirement-to-task mappings: Found at line 30
- ❌ Documentation instructions: NOT FOUND
- ❌ Acceptance criteria: NOT FOUND

**Action Required:**

- Missing patterns must be added before proceeding
- Review and add missing sections
```

If validation passes, proceed to user confirmation. If validation fails, allow user to:

- Review generated task list
- Add missing patterns
- Retry validation

### 8. Review and Refine

Present complete markdown task list to user:

"**Markdown Task List Generated**

I've created a markdown task list format for Ralph loop. Here's what I've generated:

**Story:** {title}

**Task List Structure:**

- Description: {from PRD}
- Requirements: {count} items
- Constraints: {count} items
- Requirement-to-Task Mappings: {count} explicit mappings
- Documentation Update Instructions: Included
- Acceptance Criteria: {count} items
- Completion Instructions: Included
- Completion Promise: Included

**Validation Results:**

- Pattern validation: {passed/partial failed}
- Missing patterns: {list if any}

**Traceability:**

- All {count} requirements have explicit task mappings
- Documentation update instructions will keep story AND task list synchronized
- Ready for comprehensive BMAD code review workflow

**Would you like to:**

- Review full task list content?
- Use Advanced Elicitation to explore alternative approaches?
- Use Party Mode for collaborative refinement?
- Proceed to validation loop?"

### 9. Present MENU OPTIONS

Display: **Task List Generated - Select an Option:** [R] Review Full Task List [A] Advanced Elicitation [P] Party Mode [C] Continue to Validation

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- ONLY proceed to next step when user selects 'C'
- After other menu items execution, return to this menu

#### Menu Handling Logic:

- IF R: Display full markdown task list content, then redisplay menu
- IF A: Execute {advancedElicitationTask}, and when finished redisplay menu
- IF P: Execute {partyModeWorkflow}, and when finished redisplay menu
- IF C: Store task list to workflow state, update frontmatter stepsCompleted, then load, read entire file, then execute `{nextStepFile}`
- IF Any other comments or queries: help user, then [Redisplay Menu Options](#9-present-menu-options)

### 10. Store Task List for Next Steps

Save the generated markdown task list in workflow execution context so step-05 can access it.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- Markdown task list generated with proper structure
- All requirements from PRD included
- Requirement-to-task mappings embedded ({count} mappings)
- Documentation update instructions included
- Completion promise included with correct format
- Pattern validation completed via subprocess
- Task list stored for next step
- User confirmed task list content is correct

### ❌ SYSTEM FAILURE:

- Generating task list without accessing PRD
- Missing requirement-to-task mappings
- Missing documentation update instructions
- Skipping pattern validation
- Not including completion promise
- Proceeding without user confirmation

**Master Rule:** Skipping steps is FORBIDDEN.
