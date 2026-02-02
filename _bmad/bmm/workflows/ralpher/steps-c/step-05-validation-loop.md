---
name: 'step-05-validation-loop'
description: 'Validate output completeness with parallel validation checks'

nextStepFile: './step-06-final-output.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'

advancedElicitationTask: '{project-root}/_bmad/core/workflows/advanced-elicitation/workflow.xml'
partyModeWorkflow: '{project-root}/_bmad/core/workflows/party-mode/workflow.md'
---

# Step 5: Validation Loop

## STEP GOAL:

To validate that the generated task list (markdown or JSON) is complete, correct, and ready for Ralph execution, running 7 parallel validation checks.

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
- ✅ You bring expertise in validation and quality assurance
- ✅ User brings their generated task list from step-04

### Step-Specific Rules:

- 🎯 Focus on validating generated task list completeness
- 🚫 FORBIDDEN to modify task list content
- 💬 Validate 7 aspects in parallel (Pattern 4 subprocess)
- 🎯 Use Party Mode for collaborative validation if needed
- ⚙️ Pattern 4 subprocess: 7 parallel validation checks
- 🔄 Loop validation until all checks pass

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- ⚙️ Use subprocess for parallel validation checks
- 💾 Store validation results for review
- 🔄 Loop until all validations pass
- 💾 Store validated task list for next step
- 📖 Update frontmatter stepsCompleted when proceeding to next step

## CONTEXT BOUNDARIES:

- Available context: Generated task list from step-04 (markdown or JSON)
- Focus: Validate completeness, correctness, traceability
- Limits: Validation only, don't modify task list content
- Dependencies: Step-04 must have generated a task list

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Access Generated Task List

Load the generated task list from step-04 workflow state:

- Determine format: markdown or JSON
- Load task list content

### 2. Initialize Validation Results

Create validation results structure:

```json
{
  "validation_checks": {
    "requirements_captured": null,
    "technical_context_preserved": null,
    "implementation_notes_included": null,
    "mappings_exist": null,
    "documentation_instructions_present": null,
    "completion_promise_included": null,
    "format_standards_met": null
  },
  "overall_status": "in_progress"
}
```

### 3. Launch Parallel Validation Checks

**Pattern 4 (Parallel Execution):** 7 independent validation checks running simultaneously

Launch subprocesses in parallel that:

**Check 1: All Requirements Captured**

- Validates: All acceptance criteria from original story are present in task list
- Expected count: {count from PRD}
- Returns: pass/fail + count + missing items

**Check 2: Technical Context Preserved**

- Validates: All technical context items are in constraints section
- Expected count: {count from PRD}
- Returns: pass/fail + count + missing items

**Check 3: Implementation Notes Included**

- Validates: All implementation notes are in constraints section
- Expected count: {count from PRD}
- Returns: pass/fail + count + missing items

**Check 4: Mappings Exist**

- Validates: Requirement-to-task mappings exist for all requirements
- Expected count: {count from PRD}
- Returns: pass/fail + count + unmapped requirements

**Check 5: Documentation Instructions Present**

- Validates: Documentation update instructions are included
- Checks: Both story AND task list update rules are present
- Returns: pass/fail + details

**Check 6: Completion Promise Included**

- Validates: Completion promise format is correct
- Checks: `<promise>COMPLETE</promise>` (or configured promise) exists
- Returns: pass/fail + format validation

**Check 7: Format Standards Met**

- Validates: Task list follows Ralph format standards
- Checks: Proper structure, required fields, correct syntax
- Returns: pass/fail + issues found

**Subprocesses return to parent:**

```json
{
  "check_results": [
    {
      "check_name": "requirements_captured",
      "status": "pass",
      "expected_count": 5,
      "actual_count": 5,
      "missing_items": [],
      "details": "All acceptance criteria present"
    },
    {
      "check_name": "mappings_exist",
      "status": "fail",
      "expected_count": 5,
      "actual_count": 4,
      "missing_items": ["REQ-3"],
      "details": "1 requirement has no mapping"
    }
  ],
  "summary": {
    "total_checks": 7,
    "passed_checks": 6,
    "failed_checks": 1,
    "issues_count": 1
  }
}
```

**Fallback:** If subprocess unavailable, run checks sequentially in main thread.

### 4. Aggregate Validation Results

Combine all 7 check results:

```markdown
## Validation Results Summary

**Check Results:**

| Check                                 | Status      | Details   |
| ------------------------------------- | ----------- | --------- |
| 1. Requirements Captured              | {pass/fail} | {details} |
| 2. Technical Context Preserved        | {pass/fail} | {details} |
| 3. Implementation Notes Included      | {pass/fail} | {details} |
| 4. Mappings Exist                     | {pass/fail} | {details} |
| 5. Documentation Instructions Present | {pass/fail} | {details} |
| 6. Completion Promise Included        | {pass/fail} | {details} |
| 7. Format Standards Met               | {pass/fail} | {details} |

**Overall Status:** {All checks passed / Some checks failed}

**Issues Found:**
{List any failures or missing items}

**Traceability Check:**

- All {count} requirements have mappings: {Yes/No}
- Documentation update instructions present: {Yes/No}
- Ready for comprehensive BMAD code review: {Yes/No}
```

### 5. Determine if Re-Validation Needed

Check validation summary:

**IF all checks passed:**
"**All validations passed!**

The generated task list is complete and ready for Ralph execution:

- All requirements captured
- All context preserved
- All mappings exist
- Documentation instructions present
- Completion promise correct
- Format standards met

**Proceeding to final output step...**"

**Auto-proceed** to next step.

**IF any checks failed:**
"**Validation Issues Found**

The following issues need to be addressed:

{List failures}

**Options:**

- Review issues and manually fix task list
- Use Party Mode for collaborative validation
- Re-run validation loop
- Override warnings and proceed anyway

How would you like to proceed?"

### 6. Present MENU OPTIONS (Validation Failed)

Display: **Validation Issues - Select an Option:** [F] Fix Issues Manually [P] Party Mode [R] Re-Validate [O] Override and Proceed

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- User must select how to handle validation failures

#### Menu Handling Logic:

- IF F: Present validation results, allow user to review and manually fix task list in external editor, then redisplay menu
- IF P: Execute {partyModeWorkflow} for collaborative validation, and when finished redisplay menu
- IF R: Load, read entire file, then execute this step again (re-run validation)
- IF O: Override warnings, update validation_results.status to "override_complete", then load, read entire file, then execute `{nextStepFile}`
- IF Any other comments or queries: help user, then [Redisplay Menu Options](#6-present-menu-options-validation-failed)

### 7. Store Validated Task List for Next Step

If validation passes or is overridden, store task list in workflow execution context so step-06 can access it.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- All 7 validation checks completed (in parallel)
- Validation results aggregated and presented
- User resolved any validation failures (fix or override)
- Validated task list stored for next step
- Ready for final output step

### ❌ SYSTEM FAILURE:

- Not running all 7 validation checks
- Not aggregating validation results
- Not providing options to handle validation failures
- Proceeding without user confirmation when failures exist
- Not storing validated task list for next step

**Master Rule:** Skipping steps is FORBIDDEN.
