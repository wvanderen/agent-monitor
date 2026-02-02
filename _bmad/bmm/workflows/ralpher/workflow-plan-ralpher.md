---
stepsCompleted:
  [
    'step-01-discovery',
    'step-02-classification',
    'step-03-requirements',
    'step-04-tools',
    'step-05-plan-review',
    'step-06-design',
    'step-07-foundation',
    'step-08-build-step-01',
    'step-09-build-next-step',
    'step-02-prd-extraction',
    'step-03-complexity-assessment',
    'step-04-md-generation',
    'step-04-json-generation',
    'step-05-validation-loop',
    'step-06-final-output',
  ]
created: 2026-02-01
status: WORKFLOW_COMPLETE
approvedDate: 2026-02-01
designDate: 2026-02-01
completedDate: 2026-02-01
---

# Workflow Creation Plan

## Discovery Notes

**User's Vision:**
Create a BMAD agent workflow called "Ralpher" that transforms existing BMAD story files into Ralph loop task files. This workflow addresses a key limitation with the standard `dev-story` workflow where quality degrades on larger stories due to growing context windows. The Ralph loop approach gives the agent fresh context each iteration, enabling self-correction and better results on complex implementations.

**Who It's For:**
The user will dogfood this first, then plan a public release for the BMAD community.

**What It Produces:**
A Ralph loop task file (either simple markdown task list or structured JSON feature list based on story complexity) that can be executed with `ralph <file>` for autonomous development with completion promises and iteration limits.

**Key Insights:**

- The Ralph loop (that runs on Ralpher output) is an alternative to standard BMAD `dev-story` workflow
- Ralpher workflow creates the Ralph task file, then Ralph executes it with fresh context each iteration
- Primary use case: Large/complex stories where context window management is critical
- The Ralph loop technique (Open Ralph Wiggum) provides fresh context each iteration
- Agent sees its previous work in files and git history, enabling self-correction
- Simpler stories → simple markdown task list
- Complex stories → structured JSON feature list (reduces chance of agents inappropriately modifying test definitions)
- Autonomous execution with iteration limits and completion promises
- Goal: Use context more efficiently for faster, more autonomous development

## Classification Decisions

**Workflow Name:** ralpher
**Target Path:** /home/lem/dev/catalyst/6-12/\_bmad/bmm/workflows/ralpher/

**4 Key Decisions:**

1. **Document Output:** true
2. **Module Affiliation:** BMM (software development workflows)
3. **Session Type:** single-session
4. **Lifecycle Support:** tri-modal (create + edit + validate)

**Structure Implications:**

- Needs steps-c/ (create), steps-e/ (edit), and steps-v/ (validate)
- No continuation logic needed (single-session)
- Document-producing workflow with template-based output
- Access to BMM module variables
- Target location: BMM workflows directory

## Requirements

**Flow Structure:**

- Pattern: linear → branching → validation loop
- Phases:
  1. Convert BMAD story to Ralph PRD format
  2. PRD Generation + Mapping - extract story content, create explicit requirement-to-task mappings
  3. Assess complexity, branch to simple MD or structured JSON
  4. Task List Generation - generate task list with documentation update instructions and embedded mappings
  5. Validation Loop - validate all requirements captured, explicit mappings exist, traceability preserved
- Estimated steps: 5-7 steps

**User Interaction:**

- Style: mostly autonomous with checkpoints
- Decision points: confirm complexity assessment, confirm overall plan for task list
- Checkpoint frequency: minimal - just confirm key decisions (complexity, plan)

**Inputs Required:**

- Required: BMAD story file path
- Optional: none
- Prerequisites: none (ralph plugin is for executing output, not creating it)

**Output Specifications:**

- Type: document
- Format: free-form (minimal structure, content-driven)
- Sections: Ralph PRD format with Goal, Scope, Requirements, Constraints, Acceptance Criteria, Completion Promise
- Frequency: single output per workflow run
- **Critical additions:**
  - Explicit requirement-to-task mappings (for initial validation AND comprehensive adversarial review)
  - Documentation update instructions (Ralph agents must keep BOTH story AND task list updated)
  - Full traceability preserved (comprehensive BMAD review workflow can trace everything back to original story)

**Success Criteria:**

- Generates a high-quality prompt and task list with explicit requirement-to-task mappings
- Includes clear instructions for Ralph agents to update both story AND task list with vital docs
- No loss of important information - all traceability preserved for comprehensive BMAD review workflow
- Comprehensive BMAD review workflow (executed separately after Ralph) can trace everything back to original story
- All requirements/tasks mapped correctly to output
- Output is ready to run with Ralph immediately without manual fixes
- If it works on the first run, the user is satisfied

**Instruction Style:**

- Overall: mixed
- Notes: Prescriptive for structure/format (Ralph PRD format), but with room for creative intent for content transformation and task mapping

## Tools Configuration

**Core BMAD Tools:**

- **Party Mode:** included - Integration point: Phase 5 (Validation Loop) for collaborative validation and quality checking
- **Advanced Elicitation:** included - Integration point: Phase 5 (Validation Loop) for deep exploration to ensure nothing is missed
- **Brainstorming:** excluded - not applicable (transformation workflow, not idea generation)

**LLM Features:**

- **Web-Browsing:** excluded - not needed (all information in BMAD story file)
- **File I/O:** included - Operations: read BMAD story file, write Ralph task file (markdown/JSON)
- **Sub-Agents:** excluded - not needed (simple linear transformation)
- **Sub-Processes:** excluded - not needed (linear workflow, no parallel processing)

**Memory:**

- Type: single-session
- Tracking: None needed (simple, fast workflow)

**External Integrations:**

- None needed (self-contained transformation workflow)

**Installation Requirements:**

- None (all tools are built-in to BMAD)

## Subprocess Optimization Design

**Step 4 (generation):**

- **Pattern 1 (Grep/Regex):** Final validation search for required patterns
  - Search generated output for: completion promise format, requirement-to-task mapping syntax, documentation instruction patterns
  - Returns: structured list of patterns found/missing
  - Fallback: Perform grep in main thread
  - Context savings: Massive (returns only pattern matches, not full output file)

**Step 5 (validation loop):**

- **Pattern 4 (Parallel Execution):** 7 independent validation checks running simultaneously
  - Checks: Acceptance criteria mapped, technical context preserved, implementation notes included, mappings exist, docs instructions present, completion promise included, format standards met
  - Returns: structured array of validation results with pass/fail status and details
  - Fallback: Run checks sequentially in main thread
  - Performance gain: Parallel validation reduces total time

**Universal fallback rule for all steps:**

- If subprocess/subagent unavailable, perform operations in main context thread

## Workflow Design

**Step Structure (6 steps total):**

1. **step-01-init.md** (Init Step With Input Discovery)
   - Goal: Initialize workflow and discover/load BMAD story file
   - User provides story file path
   - Parse story structure (frontmatter, sections)
   - Auto-proceed to step 2
   - Menu: Auto-proceed (no user choice)

2. **step-02-prd-extraction.md** (Middle Step - Standard)
   - Goal: Extract story content and create Ralph PRD format
   - Extract: title, description, acceptance criteria, technical context, implementation notes
   - Create explicit requirement-to-task mappings for traceability
   - Build Ralph PRD with Goal, Scope, Requirements, Constraints
   - Advanced Elicitation available here
   - Menu: Standard A/P/C

3. **step-03-complexity-assessment.md** (Branch Step)
   - Goal: Assess complexity and branch to appropriate format
   - Analyze: acceptance criteria count, technical complexity, dependencies
   - Present complexity assessment
   - User checkpoint: Confirm MD or JSON format
   - Branches to step-04-md-generation OR step-04-json-generation
   - Menu: Custom (M for markdown, J for JSON)

4. **step-04-md-generation.md** OR **step-04-json-generation.md** (Middle Step - Standard)
   - Goal: Generate task list in chosen format
   - For MD: Create simple numbered task list with mappings
   - For JSON: Create structured feature list with categories, descriptions, steps, passes flags
   - Embed documentation update instructions (keep both story AND task list updated)
   - Embed requirement-to-task mappings for traceability
   - Pattern 1 subprocess: Final validation grep search for required patterns
   - Menu: Standard A/P/C

5. **step-05-validation-loop.md** (Validation Sequence Step)
   - Goal: Validate output completeness
   - Pattern 4 subprocess: 7 parallel validation checks
   - Check: all requirements captured, mappings exist, traceability preserved
   - Check: documentation instructions present
   - Check: completion promise included
   - Loop until validation passes
   - Party Mode available for collaborative validation
   - Menu: Auto-proceed through validation sequence

6. **step-06-final-output.md** (Final Step)
   - Goal: Save final Ralph task file
   - Write output to appropriate location
   - Provide summary and next steps (run with Ralph)
   - Mark workflow complete
   - Menu: None (final step)

**File Structure:**

```
/home/lem/dev/catalyst/6-12/_bmad/bmm/workflows/ralpher/
├── workflow.md                    (main workflow entry point)
├── data/                           (no data files needed - simple transformation)
└── steps-c/                         (create mode)
    ├── step-01-init.md
    ├── step-02-prd-extraction.md
    ├── step-03-complexity-assessment.md
    ├── step-04-md-generation.md
    ├── step-04-json-generation.md
    ├── step-05-validation-loop.md
    └── step-06-final-output.md
```

**For tri-modal (edit/validate modes - to be implemented later):**

- `steps-e/` (edit mode) - separate step files
- `steps-v/` (validate mode) - separate step files
- Data folder is SHARED between modes

**Role and Persona:**

- Primary Role: BMAD Story Transformation Specialist
- Expertise: BMAD story structure, Ralph loop task file formats, requirement-to-task mapping, complexity assessment
- Communication Style: Methodical and analytical, collaborative on checkpoints, mostly autonomous between checkpoints
- Collaborative Level: Mixed - prescriptive for structure/format, flexible for creative content transformation
- Tone: Professional, precise, focused on traceability and quality

**Data Flow:**

- Step 1 → Step 2: Parsed BMAD story → extracted metadata
- Step 2 → Step 3: Ralph PRD draft + mappings → complexity assessment
- Step 3 → Step 4: Complexity assessment + user format choice → task list in chosen format
- Step 4 → Step 5: Complete Ralph task file → validation results
- Step 5 → Step 6: Validated Ralph task file → final saved file

**Validation and Error Handling:**

- Step 5 has 7 parallel validation checks
- Error recovery: Invalid path → prompt again, missing sections → warn/allow, validation failures → loop/override
- Recovery mechanisms: User can abort at checkpoints, validation loop allows manual override

**Interaction Patterns:**

- Step 1: Auto-proceed
- Step 2: Standard A/P/C (Advanced Elicitation, Party Mode, Continue)
- Step 3: Branching (M for markdown, J for JSON)
- Step 4: Standard A/P/C (Advanced Elicitation, Party Mode, Continue)
- Step 5: Validation sequence - auto-proceed through checks
- Step 6: Final step - no menu

## Step 01 Build Complete

**Created:**

- steps-c/step-01-init.md

**Step Configuration:**

- Type: non-continuable (single-session)
- Input Discovery: yes (BMAD story file path)
- Next Step: step-02-prd-extraction.md
- Menu Pattern: auto-proceed (no user choice after successful load)

**Key Features:**

- Validates story file exists
- Parses BMAD story structure (frontmatter + sections)
- Extracts: story_id, title, status, acceptance criteria, technical context, implementation notes
- Handles missing frontmatter gracefully
- Confirms story content before proceeding
- Stores parsed structure for next step

## Step 02 Build Complete

**Created:**

- steps-c/step-02-prd-extraction.md

**Step Configuration:**

- Type: Middle Step (Standard)
- Outputs to: workflow state (Ralph PRD for next steps)
- Next Step: step-03-complexity-assessment.md
- Menu Pattern: Standard A/P/C (Advanced Elicitation, Party Mode, Continue)

**Key Features:**

- Extracts story content (title, description, acceptance criteria, technical context, implementation notes)
- Transforms content into Ralph PRD format (Goal, Requirements, Constraints, Acceptance Criteria, Mappings)
- Creates explicit requirement-to-task mappings for traceability ({count} items)
- Adds documentation update instructions (keep story AND task list synchronized)
- Adds Ralph loop completion instructions
- Stores PRD for next steps
- User can review with A/P, proceed with C

## Step 03 Build Complete

**Created:**

- steps-c/step-03-complexity-assessment.md

**Step Configuration:**

- Type: Branch Step
- Outputs to: workflow state (complexity assessment + format choice)
- Next Steps: step-04-md-generation.md OR step-04-json-generation.md (branches)
- Menu Pattern: Custom (M for markdown, J for JSON)

**Key Features:**

- Analyzes PRD content (requirements count, constraints complexity)
- Calculates complexity score (Simple/Moderate/Complex)
- Recommends format: MD task list (simple/moderate) or JSON feature list (complex)
- Provides clear rationale for format choice
- User must select format before proceeding

## Step 04 (MD) Build Complete

**Created:**

- steps-c/step-04-md-generation.md

**Step Configuration:**

- Type: Middle Step (Standard)
- Outputs to: workflow state (markdown task list)
- Next Step: step-05-validation-loop.md
- Menu Pattern: Standard A/P/C (Advanced Elicitation, Party Mode, Continue)

**Key Features:**

- Generates simple markdown task list format
- Embeds requirement-to-task mappings from PRD ({count} items)
- Includes documentation update instructions (story + task list synchronization)
- Includes completion promise format
- Pattern 1 subprocess: Validates required patterns (completion promise, mappings, docs instructions)
- User can review with A/P, proceed with C

## Step 04 (JSON) Build Complete

**Created:**

- steps-c/step-04-json-generation.md

**Step Configuration:**

- Type: Middle Step (Standard)
- Outputs to: workflow state (JSON feature list)
- Next Step: step-05-validation-loop.md
- Menu Pattern: Standard A/P/C (Advanced Elicitation, Party Mode, Continue)

**Key Features:**

- Generates structured JSON feature list format
- Embeds requirement-to-task mappings from PRD ({count} items)
- Includes documentation update instructions (story + task list synchronization)
- Includes completion promise format
- Pattern 1 subprocess: Validates required patterns (completion_promise, requirement_mappings, documentation_update_instructions, features, completion_instructions)
- Each feature links to original requirement ID for traceability
- User can review with A/P, proceed with C

## Step 05 Build Complete

**Created:**

- steps-c/step-05-validation-loop.md

**Step Configuration:**

- Type: Validation Sequence Step
- Outputs to: workflow state (validation results)
- Next Step: step-06-final-output.md
- Menu Pattern: Auto-proceed through validation sequence (or manual on failure)

**Key Features:**

- Runs 7 parallel validation checks (Pattern 4 subprocess)
- Checks: requirements captured, technical context preserved, implementation notes included, mappings exist, docs instructions present, completion promise included, format standards met
- Aggregates results and presents validation summary
- Allows: Manual fix, Party Mode, Re-validate, Override and proceed
- Loops until all validations pass
- Stores validated task list for next step

## Step 06 Build Complete

**Created:**

- steps-c/step-06-final-output.md

**Step Configuration:**

- Type: Final Step (Completion)
- Outputs to: Ralph task file on disk
- Next Step: None (workflow complete)
- Menu Pattern: None (final step)

**Key Features:**

- Saves validated task list to disk at appropriate location
- Determines output filename based on story_id and timestamp
- Supports both markdown and JSON formats
- Marks workflow as complete in plan
- Provides comprehensive summary with next steps
- Includes Ralph execution command
- References BMAD code review workflow for post-Ralph validation

---

## Memory Management Tasks Added (Feb 2, 2026)

After encountering OOM issues with Ralph loop execution (22.5GB memory peak), 10 memory management cleanup tasks were added to the Ralph task file to address test suite memory leaks.

### Tasks Added

All memory management tasks (TASK-MM-1 through TASK-MM-10) are now included in `ralph-task-10-3-2026-02-01.json` and will be executed by the Ralph loop.

### Task Summaries

1. **TASK-MM-1**: Add afterEach cleanup hooks to all test files
2. **TASK-MM-2**: Audit and fix test mock accumulation  
3. **TASK-MM-3**: Optimize test fixtures for memory efficiency
4. **TASK-MM-4**: Add memory leak detection tests
5. **TASK-MM-5**: Fix Worker instance cleanup in timer tests
6. **TASK-MM-6**: Fix subscription/observer cleanup in store tests
7. **TASK-MM-7**: Add memory profiling to test suite
8. **TASK-MM-8**: Document memory management patterns for tests
9. **TASK-MM-9**: Verify memory-capped test runners work correctly
10. **TASK-MM-10**: Add pre-commit validation for test memory patterns

### Implementation Notes

These tasks address the root causes of the OOM issue:
- Missing afterEach cleanup hooks causing test fixture accumulation
- Mock objects created but never cleared across test runs
- Worker instances not properly terminated
- Store subscriptions not unsubscribed
- Fixtures recreated on every test instead of cached

### Verification

After completing these tasks, run:
- `npm run test:mem` - Verify all tests pass with memory caps
- `npm run test:bun` - Test with Bun runtime (better memory management)

### Files Updated

- `10-3/_bmad-output/ralph-task-10-3-2026-02-01.json` - Added 10 memory management tasks
- `README.md` - Added test:mem, test:mem:ui, test:bun scripts
- `AGENTS.md` - Updated testing section with memory-capped commands

