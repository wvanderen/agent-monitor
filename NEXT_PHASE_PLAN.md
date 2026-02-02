# Agent Monitor: Next Phase Implementation Plan

## Current Status ✅

**Phase 1 Complete (Foundation):**
- Endpoint monitoring (HTTP checks with configurable intervals)
- Supervisor-based fault tolerance (auto-restart on crash)
- Coordinator aggregation (collects results from all endpoints)
- Interactive console (Monitor.Console for management)
- Process registry (find checkers by URL)
- Hot reloading (add/remove endpoints without restart)

## Next Phases 🚀

### Phase 2: Intelligence Layer
**Goal:** Hook coordinator up to an LLM for smart alert routing and analysis

**Components:**
```
AgentMonitor.Coordinator
└── LLM Router (New)
    ├── Claude AI (analysis + routing)
    ├── OpenAI (faster decisions)
    ├── OpenRouter (cost-effective, privacy-friendly, best model variety)
    └── Local models (privacy, cost)

AgentMonitor.EndpointChecker
└── AI-Powered Analysis (Enhanced)
    ├── Anomaly detection (baseline deviation)
    ├── Root cause analysis (historical patterns)
    └── Recovery suggestions (LLM recommendations)
```

**Features:**
- [ ] Smart alert routing (LLM determines severity based on patterns)
- [ ] Anomaly detection (learn baseline, flag deviations)
- [ ] Root cause analysis (correlate failures across endpoints)
- [ ] Automated recovery suggestions (LLM suggests fixes)
- [ ] Alert deduplication (don't spam for known issues)

**Implementation Tasks:**
1. Add LLM service module (lib/llm_router.ex)
2. Enhance coordinator with AI decision making
3. Store baseline metrics for anomaly detection
4. Implement alert deduplication logic

**Estimated Effort:** 2-3 days

---

### Phase 3: Tool Integration
**Goal:** Add actionable notifications - not just alerts, but tools to fix problems

**Components:**
```
AgentMonitor.Alerts
├── Slack Integration
├── Email Integration
├── SMS Integration (optional)
└── PagerDuty Integration (optional)

AgentMonitor.Workflows
└── Automated Remediation (New)
    ├── Restart services
    ├── Roll back deployments
    ├── Scale up/down
    └── Run health checks
```

**Features:**
- [ ] Slack webhook notifications with severity routing
- [ ] Email alerts with detailed incident reports
- [ ] SMS for critical alerts (on-call escalation)
- [ ] PagerDuty integration for production systems
- [ ] Automated remediation workflows (restart unhealthy services)
- [ ] Incident response playbooks (run predefined fix sequences)

**Implementation Tasks:**
1. Add notification service abstraction (lib/notifications.ex)
2. Implement Slack client with webhooks
3. Add email template system (HTML/text)
4. Create automated remediation runner
5. Build incident playbook DSL (declare fix steps in config)

**Estimated Effort:** 3-4 days

---

### Phase 4: Multi-Agent Workflows
**Goal:** Chain multiple agents together - monitoring triggers investigation, investigation triggers fixes

**Components:**
```
AgentMonitor.Orchestrator (New)
└── Multi-Agent Coordinator
    ├── Monitor Agent (observes endpoints)
    ├── Investigation Agent (diagnoses issues)
    ├── Remediation Agent (applies fixes)
    └── Verification Agent (confirms resolution)

AgentMonitor.Conversation (New)
└── Stateful Dialog Manager
    ├── Store conversation history
    ├── Maintain context across agent calls
    └── Support handoff between agents
```

**Features:**
- [ ] Agent chaining (monitor → investigate → remediate → verify)
- [ ] Conversation history (remember past incidents)
- [ ] Context passing (findings flow to next agent)
- [ ] Parallel agent execution (run multiple agents simultaneously)
- [ ] Human-in-the-loop (ask for approval on critical actions)
- [ ] Agent marketplace (swap in different LLMs or tools)

**Implementation Tasks:**
1. Build agent orchestration DSL (declare workflows in config)
2. Implement conversation storage (ETS tables for state)
3. Add agent-to-agent messaging
4. Create workflow executor (run multi-step sequences)
5. Build conversation UI (show agent dialog history)

**Estimated Effort:** 5-7 days

---

### Phase 5: Dashboard & Visualization
**Goal:** Real-time web UI for monitoring, alerts, and agent orchestration

**Components:**
```
AgentMonitor.Dashboard (New - Phoenix LiveView)
├── Real-time Metrics
│   ├── Endpoint status grid
│   ├── Historical uptime graphs
│   ├── Alert timeline
│   └── Agent conversation feed

AgentMonitor.Intelligence (New)
├── AI Analysis Panel
│   ├── Anomaly detection visualization
│   ├── Root cause suggestions
│   └── Alert severity breakdown

AgentMonitor.Workflows (New)
├── Incident Management
│   ├── Active incidents list
│   ├── Remediation playbook runner
│   └── Manual trigger interface
```

**Features:**
- [ ] Phoenix LiveView dashboard (real-time updates)
- [ ] Historical uptime graphs (7-day, 30-day views)
- [ ] Agent conversation visualization (show dialog between agents)
- [ ] Incident management UI (create, update, resolve)
- [ ] Playbook editor (drag-and-drop workflow builder)
- [ ] Mobile-responsive design

**Implementation Tasks:**
1. Add Phoenix LiveView dependency to mix.exs
2. Create dashboard layout and components
3. Implement WebSocket/polling for real-time updates
4. Build incident management tables and CRUD
5. Add playbook builder UI

**Estimated Effort:** 4-6 days

---

## Parallel Execution Strategy 🐱

### What to Work On Now

**Catalyst (10-3 branch):**
- Fix Ralph loop completion logic (already documented in ralph-completion-fix.md)
- Complete memory management tasks (TASK-MM-1 through TASK-MM-10)
- Get all tests passing (79 failed → 0)

**Agent Monitor (Next Phase):**
Choose one phase to start based on your priorities:

| Phase | Value | Effort | Risk |
|--------|-------|---------|-------|
| Phase 2: Intelligence | Smart alerts, better detection | 2-3 days | Medium |
| Phase 3: Tools | Actionable notifications, not just alerts | 3-4 days | Low |
| Phase 4: Multi-Agent | Full orchestration, conversation history | 5-7 days | High (complex) |
| Phase 5: Dashboard | Visual management, better UX | 4-6 days | Low |

**Recommended Parallel Order:**
1. **Start with Phase 2 (Intelligence)** - Medium effort, builds on solid foundation
2. **Phase 3 (Tools)** when Phase 2 is stable
3. **Phase 5 (Dashboard)** - Can be done in parallel with Phase 2-4
4. **Phase 4 (Multi-Agent)** - Save for after dashboard is stable (high complexity)

### Ralph Loop for Agent Monitor

**Phase 2 Ralph Task (Intelligence Layer):**

```bash
# Create story
cd /home/lem/dev/agent_monitor
npm run ralpher -- _bmad/stories/intelligence-layer.story.md --max-iterations 15 --completion-promise "INTELLIGENCE_COMPLETE"

# Run Ralph loop
cd /home/lem/clawd
ralph-loop --file /home/lem/dev/agent_monitor/ralph-tasks/story-intelligence-layer.ralph.md
```

**Phase 3 Ralph Task (Tools Integration):**

```bash
# Create story
cd /home/lem/dev/agent_monitor
npm run ralpher -- _bmad/stories/tool-integration.story.md --max-iterations 15 --completion-promise "TOOLS_COMPLETE"

# Run Ralph loop
cd /home/lem/clawd
ralph-loop --file /home/lem/dev/agent_monitor/ralph-tasks/story-tool-integration.ralph.md
```

---

## Story Templates for Agent Monitor

### Intelligence Layer Story Template

**File:** _bmad/stories/intelligence-layer.story.md

```yaml
---
story_id: intelligence-layer-2024-02
title: Add AI Intelligence Layer to Agent Monitor
status: in-progress
---

## Description
Enhance Agent Monitor with AI-powered alert routing and anomaly detection. Currently, system can monitor endpoints and alert on failures, but lacks intelligent analysis to determine severity and suggest fixes.

## Acceptance Criteria
- [ ] LLM router service integrates with coordinator for smart alert routing
- [ ] Anomaly detection baseline is established and learns from historical data
- [ ] Root cause analysis correlates failures across multiple endpoints
- [ ] Alert deduplication prevents spam notifications for known issues
- [ ] Recovery suggestions from LLM are displayed in console output
- [ ] E2E tests verify intelligent routing (e.g., low severity alerts not escalated)

## Technical Context
- [ ] Coordinator needs new message handler for LLM routing requests
- [ ] Endpoint checker results need enhanced structure (include metrics, not just up/down)
- [ ] Anomaly detection requires baseline storage (ETS table for historical metrics)
- [ ] LLM integration needs configuration (API keys, model selection)
- [ ] Alert deduplication needs time window (don't alert on same issue within 5 minutes)

## Implementation Notes
- [ ] Start with Claude AI for analysis (already have access)
- [ ] Consider OpenAI for faster decisions if cost is acceptable
- [ ] Use ETS tables for in-memory metrics (Elixir strength)
- [ ] Implement sliding window for anomaly detection (compare last N checks to baseline)
- [ ] Add severity levels (INFO, WARNING, ERROR, CRITICAL) based on LLM analysis
- [ ] Console command: Monitor.Console.analyze(url) for on-demand analysis

---

### Tool Integration Story Template

**File:** _bmad/stories/tool-integration.story.md

```yaml
---
story_id: tool-integration-2024-02
title: Add Notification Tools and Automated Remediation
status: in-progress
---

## Description
Add actionable notifications and automated remediation workflows to Agent Monitor. Currently, system only alerts via console - need Slack, email, and automated fix execution.

## Acceptance Criteria
- [ ] Slack webhook integration sends alerts with severity routing
- [ ] Email templates generate HTML/text incident reports
- [ ] Automated remediation can restart unhealthy services
- [ ] Incident response playbooks run predefined fix sequences
- [ ] Notification service abstraction allows easy addition of new channels
- [ ] E2E tests verify notification delivery and remediation execution

## Technical Context
- [ ] Supervisor needs new child spec for remediation workers
- [ ] Coordinator needs notification dispatcher
- [ ] Email service requires SMTP configuration or API integration
- [ ] Slack client needs webhook handling and rate limiting
- [ ] Remediation runner needs process isolation (don't crash monitor on bad playbook)

## Implementation Notes
- [ ] Start with Slack (highest impact, familiar stack)
- [ ] Use Resend/SendGrid for email (better deliverability)
- [ ] Playbook DSL should be YAML/JSON based (easy to read and write)
- [ ] Remediation jobs should be supervised (fault tolerance!)
- [ ] Add Monitor.Console.remediate(url, playbook_id) command

---

## Decision Framework

### Should We Do This?

| Factor | Consideration |
|--------|---------------|
| **Value** | Intelligence layer transforms "monitor" into "understand" - 10x value |
| **Time** | You're fixing Catalyst tests anyway - can Ralph in parallel |
| **Complexity** | Builds on solid Phase 1 foundation - not greenfield |
| **Interest** | Elixir's fault tolerance teaches lessons for other systems |
| **Learning** | Agent orchestration patterns apply to any AI system |

### Decision: **YES** ✅

Agent Monitor is low-risk, high-value work that:
- Can be Ralph'd in parallel with Catalyst test fixes
- Teaches valuable patterns (fault tolerance, concurrent processes)
- Builds toward multi-agent orchestration (the future)
- Leverages Elixir's strengths (BEAM VM, supervisor trees)

---

## Summary

**Total Estimated Effort:** 14-20 days across all phases

**Parallel Strategy:**
1. **Catalyst:** Fix tests (immediate value, user blocked)
2. **Agent Monitor Phase 2:** Intelligence layer (medium effort, high value)
3. **Agent Monitor Phase 3:** Tool integration (medium effort)
4. **Phase 5:** Dashboard (low effort, good for demo)

**What We're Building:**

```
Current: HTTP Endpoint Monitoring
     ↓
Next Phase: AI-Powered Monitoring with Intelligent Alerts
     ↓
Future: Multi-Agent Orchestration with Workflows
     ↓
Ultimate: Self-Healing AI Systems (auto-diagnose + auto-fix)
```

This is the path from "monitor" to "understand" to "act autonomously." 🚀
