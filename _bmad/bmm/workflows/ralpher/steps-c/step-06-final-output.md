---
name: 'step-06-final-output'
description: 'Save final Ralph task file and complete workflow'

workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'
---

# Step 6: Final Output

## STEP GOAL:

To save the validated task list (markdown or JSON) to disk and complete the Ralpher workflow.

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
- ✅ You bring expertise in file operations and workflow completion
- ✅ User brings their validated task list from step-05

### Step-Specific Rules:

- 🎯 Focus on saving the task list to disk
- 🚫 FORBIDDEN to make any modifications to task list
- 💬 Provide clear output location and next steps
- 🚪 No menu - this is final step
- ✅ Mark workflow complete and provide summary

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Write task list to disk at appropriate location
- 📖 Mark workflow complete
- 💬 Provide summary and Ralph execution instructions

## CONTEXT BOUNDARIES:

- Available context: Validated task list from step-05 (markdown or JSON)
- Focus: Save to disk and complete workflow
- Limits: Write only, no modifications
- Dependencies: Step-05 must have validated task list successfully

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Determine Output Location

Based on the task list format, determine output location:

```yaml
output_filename: 'ralph-task-{story_id}-{timestamp}.md'

# For JSON format, use .json extension:
# output_filename: "ralph-task-{story_id}-{timestamp}.json"

output_path: '{output_folder}/{output_filename}'
```

Where:

- `story_id` is from the original BMAD story
- `timestamp` is current date in format YYYY-MM-DD
- `output_folder` is determined by user preference or project default

### 2. Determine Output Filename Format

Based on format from step-03 (markdown or JSON):

**If markdown format:**

- Output filename: `ralph-task-{story_id}-{timestamp}.md`
- Extension: `.md`

**If JSON format:**

- Output filename: `ralph-task-{story_id}-{timestamp}.json`
- Extension: `.json`

### 3. Write Task List to Disk

Save the validated task list to the determined output location:

```bash
Write validated task list (markdown or JSON) to:
{output_path}
```

Ensure:

- File permissions are correct
- Directory exists (create if needed)
- Write operation completes successfully

### 4. Confirm File Write

Verify the file was written successfully:

```markdown
**Task List Saved**

✅ Task list written to: {output_path}

- Format: {markdown/JSON}
- Size: {file size}
- Created: {timestamp}
```

### 5. Update Workflow Plan

Mark workflow as complete in the plan:

```yaml
status: WORKFLOW_COMPLETE
completedDate: { current_date }
allStepsBuilt: [
    'step-01-init.md',
    'step-02-prd-extraction.md',
    'step-03-complexity-assessment.md',
    'step-04-md-generation.md', # OR step-04-json-generation.md
    'step-05-validation-loop.md',
    'step-06-final-output.md',
  ]
```

### 6. Provide Summary and Next Steps

Present comprehensive workflow completion summary:

````markdown
**🎉 Ralpher Workflow Complete!**

**Story Transformated:**

- Original BMAD Story: {story_title} ({story_id})
- Status: {status}

**Task List Generated:**

- Format: {markdown/JSON}
- Output File: {output_path}
- Requirements: {count} items
- Requirement-to-Task Mappings: {count} mappings

**Validation:**

- All 7 validation checks passed
- Traceability: Verified (story + task list can be synchronized)

**Ready for Ralph Execution:**

Your task list is ready to run with the Ralph loop tool:

```bash
# For markdown format:
ralph "{output_path}" --max-iterations 20

# For JSON format:
ralph "{output_path}" --max-iterations 20

# Adjust iterations based on complexity:
# Simple stories (15 points): 10-15 iterations
# Moderate stories (15-30 points): 15-25 iterations
# Complex stories (30+ points): 20-30 iterations
```
````

**Ralph Loop Benefits:**

- Fresh context windows each iteration
- Self-correction based on previous work
- Autonomous execution with completion promises
- Comprehensive BMAD code review workflow can trace everything back to original story

**After Ralph Loop:**
Once Ralph completes, run the comprehensive BMAD code review workflow to validate:

- All acceptance criteria met
- No information loss
- Traceability preserved from implementation back to requirements

**Next Steps:**

1. Review the generated task list
2. Run Ralph loop: `ralph "{output_path}"`
3. After Ralph completes, run BMAD code review workflow
4. Implement any final adjustments based on code review

**File Locations:**

- BMAD Story: {original_story_path}
- Ralph Task List: {output_path}
- Workflow Plan: {workflow_plan_path}

Would you like to review any of these files now?

```

### 7. No Menu (Final Step)

This is the final step - workflow is complete. No menu options.

### 8. End Workflow

Mark workflow as complete and provide final summary:

"**Workflow Summary**

You've successfully created a Ralph loop task file from your BMAD story.

**Workflow Steps Completed:**
- ✅ Step 1: Initialized and loaded BMAD story
- ✅ Step 2: Extracted content and created Ralph PRD
- ✅ Step 3: Assessed complexity and selected format
- ✅ Step 4: Generated task list ({format}) with mappings
- ✅ Step 5: Validated completeness and traceability
- ✅ Step 6: Saved final task file

**Deliverables:**
1. Ralph Task List: {output_path} - Ready for Ralph execution
2. Requirement-to-Task Mappings: {count} items for traceability
3. Documentation Update Instructions: Included (story + task list synchronization)

**Ralph Execution:**
Run: `ralph "{output_path}"`

**BMAD Code Review:**
After Ralph completes, run comprehensive BMAD code review workflow to validate implementation against original story requirements.

**Workflow Complete!** Thank you for using Ralpher."

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:
- Task list successfully written to disk at {output_path}
- File permissions correct
- Workflow plan updated to WORKFLOW_COMPLETE status
- Completion summary provided with clear next steps
- Ralph execution instructions included
- BMAD code review workflow reference included
- Workflow marked complete

### ❌ SYSTEM FAILURE:
- Not writing task list to disk
- Incorrect output location or permissions
- Not updating workflow plan to complete status
- Missing completion summary or next steps
- Not marking workflow complete

**Master Rule:** Skipping steps is FORBIDDEN.
```
