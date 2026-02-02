---
name: 'step-04-json-generation'
description: 'Generate structured JSON feature list with requirement-to-task mappings and documentation update instructions'

nextStepFile: './step-05-validation-loop.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'

advancedElicitationTask: '{project-root}/_bmad/core/workflows/advanced-elicitation/workflow.xml'
partyModeWorkflow: '{project-root}/_bmad/core/workflows/party-mode/workflow.md'
---

# Step 4: JSON Feature List Generation

## STEP GOAL:

To generate a structured JSON feature list for Ralph loop, including requirement-to-task mappings and documentation update instructions.

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
- ✅ You bring expertise in Ralph JSON feature list format and JSON structure
- ✅ User brings their PRD content and complexity assessment
- ✅ Together we create a structured JSON task list

### Step-Specific Rules:

- 🎯 Focus on generating JSON feature list format
- 🚫 FORBIDDEN to generate markdown format (that's step-04-md-generation)
- 💬 Embed requirement-to-task mappings from PRD
- 💬 Include documentation update instructions
- 🎯 Use Advanced Elicitation and Party Mode for quality enhancement
- ⚙️ Pattern 1 subprocess: Final validation grep for required patterns

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Generate JSON feature list with embedded mappings
- ⚙️ Use subprocess for final validation (grep for required patterns)
- 💾 Store JSON for next step
- 📖 Update frontmatter stepsCompleted when proceeding to next step

## CONTEXT BOUNDARIES:

- Available context: Ralph PRD from step-02, complexity assessment (Complex - using JSON)
- Focus: Generate JSON feature list format with mappings
- Limits: JSON format only, no markdown
- Dependencies: Steps 02 and 03 must have completed successfully

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Access PRD and Assessment

Load and review:

- Ralph PRD content from step-02 (requirements, constraints, mappings)
- Complexity assessment from step-03 (Complex - confirmed JSON format)

### 2. Create JSON Feature List Structure

Generate structured JSON feature list:

```json
{
  "completion_promise": "<promise>COMPLETE</promise>",
  "max_iterations": 20,
  "active": true,
  "task_format": "structured_json_feature_list",
  "requirement_mappings": {
    "{story_id}": {
      "title": "{title}",
      "requirements": [
        {
          "id": "REQ-1",
          "description": "{from PRD}",
          "mapped_to_task": "Task 1: {description}"
        },
        {
          "id": "REQ-2",
          "description": "{from PRD}",
          "mapped_to_task": "Task 2: {description}"
        }
      ]
    }
  },
  "documentation_update_instructions": {
    "story_file": "{path to original story}",
    "task_list_file": "this file",
    "synchronization_rules": [
      "Update story when completing requirements",
      "Update task list with progress",
      "Add new documentation to both files"
    ]
  },
  "features": [
    {
      "category": "functional",
      "description": "{requirement description}",
      "steps": ["{step 1}", "{step 2}", "{step 3}"],
      "passes": false
    },
    {
      "category": "functional",
      "description": "{requirement description}",
      "steps": ["{step 1}", "{step 2}"],
      "passes": false
    }
  ]
}
```

### 3. Embed Requirement-to-Task Mappings

For each acceptance criterion from the PRD, create a feature:

```json
{
  "category": "functional",
  "description": "{acceptance criterion description}",
  "steps": [
    "Implement {specific implementation details}",
    "Verify {verification criteria}",
    "Test {testing approach}"
  ],
  "passes": false,
  "requirement_id": "REQ-{N}",
  "mapped_from": "{story_id}"
}
```

**JSON structure rationale:**

- `category`: Organizes features (functional, ui, technical, etc.)
- `description`: The original requirement from the story
- `steps`: Implementation steps to complete this requirement
- `passes`: Track completion (Ralph agents update this to true)
- `requirement_id`: Links back to original story requirement
- `mapped_from`: Story source for traceability

### 4. Include Documentation Update Instructions

Add documentation synchronization instructions to JSON:

```json
"documentation_update_instructions": {
  "story_file": "{path to original BMAD story}",
  "task_list_file": "this JSON file",
  "synchronization_rules": [
    {
      "rule": "Update Story",
      "description": "When completing a requirement, update the corresponding checkbox in the original BMAD story file",
      "action": "Update story file's acceptance_criteria section"
    },
    {
      "rule": "Update Task List",
      "description": "Mark features as passes: true in this JSON as implementation progresses",
      "action": "Update the passes field in features array"
    },
    {
      "rule": "Add Vital Documentation",
      "description": "If new technical decisions, API endpoints, or architectural patterns emerge, document them in both files",
      "action": "Add to story's technical_context AND this JSON's documentation section"
    }
  ],
  "why_important": [
    "Enables comprehensive BMAD code review workflow to trace everything back to original story",
    "Preserves traceability across the Ralph loop and code review lifecycle",
    "Prevents information loss between Ralph iterations and code review",
    "Reduces chance of agents inappropriately modifying test definitions (JSON is harder to modify than markdown)"
  ]
}
```

### 5. Add Completion Instructions

Add Ralph loop completion instructions to JSON:

```json
"completion_instructions": {
  "promise_format": "<promise>COMPLETE</promise>",
  "loop_behavior": "Work iteratively until ALL acceptance criteria are met and verified",
  "post_iteration_actions": [
    "Implement requirements in order",
    "Run tests and fix failures",
    "Update both original BMAD story file AND this JSON file with progress",
    "Verify implementation against requirements"
  ],
  "completion_criteria": [
    "All acceptance criteria satisfied",
    "All tests pass",
    "All features marked passes: true",
    "Documentation updated in both story and task list"
  ],
  "output_promise": "When genuinely complete and all criteria satisfied, output exactly: <promise>COMPLETE</promise>",
  "warning": "DO NOT output the promise until all acceptance criteria are truly satisfied"
}
```

### 6. Validate Required Patterns with Subprocess

**Pattern 1 (Grep/Regex):** Final validation search for required patterns

Launch a subprocess that:

- Searches the generated JSON for required patterns
- Returns: structured list of patterns found/missing

**Required patterns to search for:**

- `completion_promise` field exists and has correct value
- `requirement_mappings` object exists with story_id
- `documentation_update_instructions` object exists
- `features` array exists with at least one item
- `completion_instructions` object exists

**Subprocess returns to parent:**

```json
{
  "patterns_found": [
    {
      "pattern": "completion_promise",
      "found": true,
      "field": "completion_promise"
    },
    {
      "pattern": "requirement_mappings",
      "found": true,
      "field": "requirement_mappings"
    }
  ],
  "patterns_missing": [
    {
      "pattern": "documentation_instructions",
      "found": false,
      "expected_field": "documentation_update_instructions"
    }
  ],
  "summary": {
    "total_patterns_checked": 5,
    "patterns_found_count": 2,
    "patterns_missing_count": 1
  }
}
```

**Fallback:** If subprocess unavailable, perform grep/JSON checks in main thread.

### 7. Review Validation Results

Review subprocess validation results:

```markdown
**Pattern Validation Results:**

- ✅ completion_promise: Found
- ✅ requirement_mappings: Found
- ❌ documentation_instructions: NOT FOUND - Expected field: documentation_update_instructions

**Action Required:**

- Missing patterns must be added before proceeding
- Review and add missing fields to JSON
```

If validation passes, proceed to user confirmation. If validation fails, allow user to:

- Review generated JSON structure
- Add missing fields
- Retry validation

### 8. Review and Refine

Present complete JSON feature list to user:

"**JSON Feature List Generated**

I've created a structured JSON feature list for Ralph loop. Here's what I've generated:

**Story:** {title} ({story_id})

**JSON Structure:**

- Features: {count} feature items generated
- Requirement-to-Task Mappings: {count} explicit mappings
- Documentation Update Instructions: Included with {count} synchronization rules
- Completion Instructions: Included
- Completion Promise: Included

**Traceability:**

- All {count} acceptance criteria have explicit JSON feature mappings
- Each feature links to original requirement ID
- Documentation update instructions will keep story AND JSON synchronized
- JSON format reduces risk of agents inappropriately modifying test definitions

**Ready for comprehensive BMAD code review workflow.**

**Would you like to:**

- Review full JSON content?
- Use Advanced Elicitation to explore alternative approaches?
- Use Party Mode for collaborative refinement?
- Proceed to validation loop?"

### 9. Present MENU OPTIONS

Display: **JSON Feature List Generated - Select an Option:** [R] Review Full JSON [A] Advanced Elicitation [P] Party Mode [C] Continue to Validation

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- ONLY proceed to next step when user selects 'C'
- After other menu items execution, return to this menu

#### Menu Handling Logic:

- IF R: Display full JSON feature list content, then redisplay menu
- IF A: Execute {advancedElicitationTask}, and when finished redisplay menu
- IF P: Execute {partyModeWorkflow}, and when finished redisplay menu
- IF C: Store JSON to workflow state, update frontmatter stepsCompleted, then load, read entire file, then execute `{nextStepFile}`
- IF Any other comments or queries: help user, then [Redisplay Menu Options](#9-present-menu-options)

### 10. Store JSON for Next Steps

Save the generated JSON feature list in workflow execution context so step-05 can access it.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- JSON feature list generated with proper structure
- All requirements from PRD converted to features ({count} features)
- Requirement-to-task mappings embedded ({count} mappings)
- Documentation update instructions included ({count} rules)
- Completion instructions included
- Pattern validation completed via subprocess (or fallback)
- JSON stored for next step
- User confirmed JSON content is correct

### ❌ SYSTEM FAILURE:

- Generating JSON without accessing PRD
- Missing requirement-to-task mappings
- Missing documentation update instructions
- Skipping pattern validation
- Not including completion instructions
- Proceeding without user confirmation

**Master Rule:** Skipping steps is FORBIDDEN.
