---
name: 'step-03-complexity-assessment'
description: 'Assess story complexity and branch to appropriate format (MD or JSON)'

nextStepFile: './step-04-md-generation.md'
altStepFile: './step-04-json-generation.md'
workflowPlanFile: '{targetWorkflowPath}/workflow-plan-{workflow_name}.md'
---

# Step 3: Complexity Assessment

## STEP GOAL:

To assess the complexity of the BMAD story (based on PRD from step-02) and determine whether to use simple markdown task list or structured JSON feature list format for the Ralph task file.

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
- ✅ You bring expertise in complexity assessment and format selection
- ✅ User brings their PRD content and format preferences
- ✅ Together we determine optimal format for the task list

### Step-Specific Rules:

- 🎯 Focus on assessing complexity and recommending format
- 🚫 FORBIDDEN to generate task list yet (that's step-04)
- 💬 Analyze PRD content objectively
- 🎯 Provide clear complexity assessment with rationale

## EXECUTION PROTOCOLS:

- 🎯 Follow MANDATORY SEQUENCE exactly
- 💾 Assess and store complexity decision for next step
- 📖 Update frontmatter stepsCompleted when branching to format-specific step

## CONTEXT BOUNDARIES:

- Available context: Ralph PRD from step-02 (requirements count, constraints complexity)
- Focus: Assess complexity and determine optimal format (MD vs JSON)
- Limits: Assessment only, don't generate task list yet
- Dependencies: Step-02 must have created Ralph PRD

## MANDATORY SEQUENCE

**CRITICAL:** Follow this sequence exactly. Do not skip, reorder, or improvise unless user explicitly requests a change.

### 1. Analyze PRD Content

From the Ralph PRD created in step-02, analyze complexity factors:

**Requirement Count:**

- Count acceptance criteria in PRD
- More requirements → more complex implementation

**Constraints Complexity:**

- Count technical context + implementation notes
- Assess technical complexity (familiar vs unfamiliar tech, number of dependencies)

**Story Complexity Indicators:**

- Simple: < 5 requirements, straightforward tech, clear dependencies
- Moderate: 5-10 requirements, some complexity in constraints
- Complex: 10+ requirements, complex tech stack, unclear dependencies

### 2. Determine Complexity Rating

Calculate overall complexity:

```
Complexity Score = (Requirements Count × 2) + (Constraints Complexity × 3)

Simple:      < 15
Moderate:    15-30
Complex:      > 30
```

### 3. Recommend Format

Based on complexity assessment:

**Simple (< 15 points):**

- **Recommendation:** Simple markdown task list format
- **Rationale:** Fewer requirements, easier to read in markdown, Ralph agents can iterate faster with simpler format
- **Example structure:**

```markdown
# Ralph Tasks

- [ ] Task 1: Implement category sidebar
- [ ] Task 2: Add category filtering
- [ ] Task 3: Implement product grid
```

**Moderate (15-30 points):**

- **Recommendation:** Simple markdown task list format
- **Rationale:** Still manageable with markdown, good balance of structure and simplicity
- **Same as simple format**

**Complex (> 30 points):**

- **Recommendation:** Structured JSON feature list format
- **Rationale:** More requirements reduce risk of agents inappropriately modifying task definitions; JSON provides clearer structure for complex implementations
- **Example structure:**

```json
{
  "features": [
    {
      "category": "functional",
      "description": "Category list displays on left sidebar",
      "steps": ["Create sidebar component", "Wire up category API calls"],
      "passes": false
    },
    {
      "category": "functional",
      "description": "Clicking category filters product grid",
      "steps": ["Add filtering state", "Connect to product API"],
      "passes": false
    }
  ]
}
```

### 4. Present Assessment

"**Complexity Assessment Complete**

I've analyzed your BMAD story and Ralph PRD to determine the optimal task list format.

**Story:** {title} ({story_id})

**Complexity Factors:**

- Requirements: {count} acceptance criteria
- Constraints: {count} technical context + {count} implementation notes
- Complexity Score: {score}

**Assessment:** {Simple/Moderate/Complex}

**Format Recommendation:** {MD Task List / JSON Feature List}

**Rationale:**
{Brief explanation based on the analysis}

**Why this format:**

- {Explanation of why this format is optimal for this complexity level}

**Ready to proceed to task list generation?**"

### 5. Present MENU OPTIONS

Display: **Complexity Assessment - Select Format:** [M] Use Markdown Format [J] Use JSON Format

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- User MUST select format before proceeding
- After selection, proceed to corresponding step
- User can ask questions about the assessment before selecting

#### Menu Handling Logic:

- IF M: Save assessment and format choice (MD) to workflow state, update frontmatter stepsCompleted, then load, read entire file, then execute `{nextStepFile}` (step-04-md-generation.md)
- IF J: Save assessment and format choice (JSON) to workflow state, update frontmatter stepsCompleted, then load, read entire file, then execute `{altStepFile}` (step-04-json-generation.md)
- IF Any other comments or queries: help user understand the assessment, then redisplay menu

### 6. Store Assessment for Next Steps

Save the complexity assessment and format choice in workflow execution context so step-04 can access it.

## 🚨 SYSTEM SUCCESS/FAILURE METRICS:

### ✅ SUCCESS:

- Complexity assessment completed based on PRD content
- Format recommendation provided with clear rationale
- User selected format (MD or JSON)
- Assessment and format choice stored for next steps
- User understood complexity factors

### ❌ SYSTEM FAILURE:

- Skipping complexity analysis
- Not providing clear format recommendation
- Proceeding without user format selection
- Not storing assessment for next steps

**Master Rule:** Skipping steps is FORBIDDEN.
