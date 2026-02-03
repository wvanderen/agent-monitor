# Agent Monitor - Stories: Phases 4 & 5

**Project:** dev/agent_monitor
**Context:** Multi-agent orchestration system for monitoring, investigating, and remediating incidents

---

## Phase 4: Multi-Agent Workflows

### Story 4.1: Agent chaining (monitor → investigate → remediate → verify)

**As a system administrator,**
**I want agents to automatically chain together in a workflow,**
**So that incidents can be detected, investigated, fixed, and verified without manual intervention.**

**Acceptance Criteria:**
- [ ] Agent workflow engine supports sequential agent chaining
- [ ] Default workflow chain: `monitor_agent` → `investigate_agent` → `remediate_agent` → `verify_agent`
- [ ] Output from each agent is passed as input to the next agent
- [ ] Workflow can be customized per incident type or playbook
- [ ] Agents can be added/removed from workflow chain dynamically
- [ ] Workflow state is persisted (pending, in_progress, completed, failed)
- [ ] Failed workflows can be retried from the failed agent

**Technical Notes:**
- Use a directed acyclic graph (DAG) for workflow definition
- Each agent receives: `previous_agent_output`, `incident_context`, `conversation_history`
- Workflow engine tracks current position and next steps
- Support for conditional branching (e.g., skip remediation if issue is already resolved)

**Data Model:**
```elixir
defmodule AgentMonitor.Workflow do
  schema "workflows" do
    field :incident_id, :string
    field :status, :string # pending, in_progress, completed, failed
    field :current_step, :integer
    field :steps, {:array, :map} # [agent_id, status, input, output]
    field :context, :map # Shared context across workflow

    timestamps()
  end
end
```

**Effort:** High
**Priority:** High (core workflow orchestration)

---

### Story 4.2: Conversation history & context passing

**As an agent in the workflow,**
**I want to see the full conversation history and context from previous agents,**
**So that I can make informed decisions without duplicating work.**

**Acceptance Criteria:**
- [ ] Each agent has access to full conversation history from the workflow
- [ ] Context includes: previous agent outputs, incident data, system state, user inputs
- [ ] Conversation history is queryable (by agent, by time, by topic)
- [ ] Context can be summarized for long conversations (to manage token limits)
- [ ] Agents can add to conversation history during execution
- [ ] Conversation history is persisted to the database
- [ ] Context is versioned (immutable snapshots for each workflow step)

**Technical Notes:**
- Store conversation as append-only log
- Use embedding-based search for relevant historical context retrieval
- Implement context window management (summarize old messages when needed)
- Support for "context compression" for passing to LLMs

**Data Model:**
```elixir
defmodule AgentMonitor.Conversation do
  schema "conversations" do
    field :workflow_id, :string
    field :agent_id, :string
    field :role, :string # system, user, assistant
    field :content, :text
    field :metadata, :map # timestamps, tokens, etc.
    field :embedding, :vector # For semantic search

    timestamps()
  end
end
```

**Effort:** High
**Priority:** High (critical for agent collaboration)

---

### Story 4.3: Parallel agent execution

**As a system administrator,**
**I want multiple agents to run in parallel for independent tasks,**
**So that complex incidents can be resolved faster by doing multiple investigations simultaneously.**

**Acceptance Criteria:**
- [ ] Workflow engine supports parallel execution of independent agents
- [ ] Workflow DAG can have multiple branches that run concurrently
- [ ] Results from parallel agents are aggregated at convergence points
- [ ] Parallel agents have isolated contexts (no shared state during execution)
- [ ] Agent failures in one branch don't stop other branches
- [ ] Parallel execution is configurable (sequential fallback available)
- [ ] Workflow state tracks which branches are complete/in-progress

**Technical Notes:**
- Use `Task.Supervisor` or `GenStage` for parallel execution
- Implement barrier synchronization for convergence points
- Support for "first success wins" or "all must complete" strategies
- Timeout handling for stuck parallel agents

**Workflow Example:**
```elixir
# Parallel investigation
[
  parallel: [
    {:investigate_logs, :agent_1},
    {:investigate_metrics, :agent_2},
    {:investigate_dependencies, :agent_3}
  ],
  converge: :analyze_results,
  then: :remediate
]
```

**Effort:** High
**Priority:** Medium (performance optimization)

---

### Story 4.4: Human-in-the-loop approval

**As a system administrator,**
**I want to approve or reject critical agent actions before they execute,**
**So that dangerous remediation steps don't run without my oversight.**

**Acceptance Criteria:**
- [ ] Agents can request human approval for sensitive actions
- [ ] Approval requests are sent via configured channel (email, Slack, UI notification)
- [ ] Approval UI shows: agent action description, context, risk level, estimated impact
- [ ] Approvals can be: approve, reject, or approve with modifications
- [ ] Approval workflow is time-boxed (auto-reject if no response within timeout)
- [ ] Approval history is logged for audit purposes
- [ ] Approval can be pre-approved for certain agents or incident types (whitelist)

**Technical Notes:**
- Implement approval state machine: `pending` → `approved` | `rejected`
- Use webhook-based approval system for integration with external tools
- Support for "trust level" configuration (low-risk actions auto-approved)
- Approval notifications include direct links to approve/reject

**Data Model:**
```elixir
defmodule AgentMonitor.Approval do
  schema "approvals" do
    field :workflow_id, :string
    field :agent_id, :string
    field :action, :string
    field :status, :string # pending, approved, rejected, expired
    field :context, :map
    field :risk_level, :string # low, medium, high, critical
    field :expires_at, :utc_datetime
    field :approved_by, :string
    field :approved_at, :utc_datetime

    timestamps()
  end
end
```

**Effort:** Medium
**Priority:** High (safety feature)

---

### Story 4.5: Agent marketplace

**As a developer,**
**I want a marketplace to discover, install, and share agent implementations,**
**So that I can extend the system with specialized agents without building everything from scratch.**

**Acceptance Criteria:**
- [ ] Agent marketplace UI lists available agents with descriptions and capabilities
- [ ] Agents can be installed from the marketplace into local agent registry
- [ ] Agent metadata includes: name, description, author, version, capabilities, dependencies
- [ ] Marketplace supports filtering by capability (monitoring, investigation, remediation, verification)
- [ ] Agents can be rated and reviewed by users
- [ ] Agents can be shared as packages (Elixir modules or external services)
- [ ] Marketplace agents can be versioned and updated

**Technical Notes:**
- Use Hex.pm-style package format for agents
- Agents can be local modules or HTTP endpoints (webhook agents)
- Implement agent capability discovery (agents declare what they can do)
- Support for "agent templates" (starting point for custom agents)

**Agent Registry:**
```elixir
defmodule AgentMonitor.AgentRegistry do
  def list_agents(filter \\ %{})
  def install_agent(package_name)
  def get_agent_capabilities(agent_id)
  def update_agent(agent_id, new_version)
end
```

**Marketplace Schema:**
```elixir
defmodule AgentMonitor.MarketplaceAgent do
  schema "marketplace_agents" do
    field :name, :string
    field :description, :string
    field :author, :string
    field :version, :string
    field :capabilities, {:array, :string}
    field :package_url, :string
    field :rating, :float
    field :downloads, :integer
    field :is_installed, :boolean

    timestamps()
  end
end
```

**Effort:** High
**Priority:** Low (nice-to-have extensibility)

---

## Phase 5: Dashboard

### Story 5.1: Phoenix LiveView for real-time UI

**As a system administrator,**
**I want a real-time dashboard that updates without page refreshes,**
**So that I can monitor agent workflows and incidents as they happen.**

**Acceptance Criteria:**
- [ ] Dashboard is built with Phoenix LiveView for real-time updates
- [ ] Active workflows are displayed in real-time (status updates automatically)
- [ ] Agent conversations stream live as they happen
- [ ] System metrics (uptime, active incidents, agent status) update in real-time
- [ ] UI responds to server events (agent started, workflow completed, approval requested)
- [ ] LiveView uses pub/sub for efficient updates (no polling)
- [ ] Dashboard is responsive and works on mobile/tablet

**Technical Notes:**
- Use `Phoenix.LiveView` for dashboard components
- Implement `Phoenix.PubSub` for real-time event broadcasting
- Consider `Phoenix.LiveDashboard` as a base for system metrics
- Optimize for low latency (debounce rapid updates)

**LiveView Example:**
```elixir
defmodule AgentMonitorWeb.DashboardLive do
  use AgentMonitorWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe_to_events()
    end

    {:ok, assign(socket, :workflows, list_active_workflows())}
  end

  def handle_info({:workflow_update, workflow}, socket) do
    {:noreply, update_workflow(socket, workflow)}
  end
end
```

**Effort:** High
**Priority:** High (core user interface)

---

### Story 5.2: Historical uptime graphs

**As a system administrator,**
**I want to see historical uptime trends and incident patterns,**
**So that I can identify recurring issues and track system health over time.**

**Acceptance Criteria:**
- [ ] Uptime graphs show system availability over time (hourly, daily, weekly, monthly)
- [ ] Incident markers are plotted on the uptime timeline
- [ ] Graphs can be filtered by service, agent, or incident type
- [ ] Hover tooltips show incident details (when clicked, jump to incident details)
- [ ] Support for uptime comparison (current vs. previous period)
- [ ] Export data as CSV for external analysis
- [ ] Graphs use caching for fast loading of historical data

**Technical Notes:**
- Use a charting library (Chart.js, Recharts, or SVG with Phoenix)
- Pre-compute uptime aggregates (hourly/daily rollups)
- Store time-series data in PostgreSQL or specialized database (TimescaleDB)
- Implement data aggregation at query time for flexibility

**Data Model:**
```elixir
defmodule AgentMonitor.UptimeMetric do
  schema "uptime_metrics" do
    field :timestamp, :utc_datetime
    field :service_id, :string
    field :status, :string # up, down, degraded
    field :response_time_ms, :integer
    field :incident_id, :string # optional

    timestamps()
  end
end
```

**Effort:** Medium
**Priority:** Medium (analytics feature)

---

### Story 5.3: Agent conversation visualization

**As a system administrator,**
**I want to visualize agent conversations as a chat interface or flow diagram,**
**So that I can understand what agents discussed and how decisions were made.**

**Acceptance Criteria:**
- [ ] Conversation view shows chat-style interface (like messaging app)
- [ ] Messages are color-coded by agent (different agents have different colors)
- [ ] Flow diagram view shows agent workflow as a visual graph
- [ ] Nodes in the diagram represent agents, edges represent handoffs
- [ ] Clicking a node shows that agent's conversation and output
- [ ] Support for collapsing/expanding conversation threads
- [ ] Search/filter conversations by agent, time, or keyword

**Technical Notes:**
- Use a graph visualization library (D3.js, Cytoscape.js, or Mermaid)
- Chat view is straightforward LiveView
- Flow diagram requires client-side rendering of graph data
- Consider using Mermaid.js for simple workflow diagrams

**Conversation View:**
```elixir
defmodule AgentMonitorWeb.ConversationLive do
  use AgentMonitorWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="conversation-container">
      <%= for message <- @messages do %>
        <div class={"message message-#{message.agent_id}"}>
          <div class="agent-name"><%= message.agent_name %></div>
          <div class="message-content"><%= message.content %></div>
        </div>
      <% end %>
    </div>
    """
  end
end
```

**Effort:** High
**Priority:** Medium (debugging/analysis feature)

---

### Story 5.4: Incident management

**As a system administrator,**
**I want to manage incidents through the dashboard (create, assign, resolve, close),**
**So that I have a centralized place to track all incident lifecycle activities.**

**Acceptance Criteria:**
- [ ] Incident list view shows all incidents with status, severity, and assignee
- [ ] Incident detail view shows full workflow, agent conversations, and timeline
- [ ] Incidents can be created manually or auto-created by agents
- [ ] Incidents can be assigned to users or teams
- [ ] Incident states: `open`, `in_progress`, `resolved`, `closed`, `reopened`
- [ ] Severity levels: `P1` (critical), `P2` (high), `P3` (medium), `P4` (low)
- [ ] Incidents support comments, attachments, and related incident linking
- [ ] Incidents can be linked to playbooks for remediation guidance

**Technical Notes:**
- Implement incident state machine (transitions between states)
- Use Phoenix LiveView for real-time incident updates
- Support for incident templates (common incident types)
- Integrate with approval workflow (Story 4.4) for critical actions

**Data Model:**
```elixir
defmodule AgentMonitor.Incident do
  schema "incidents" do
    field :title, :string
    field :description, :text
    field :status, :string # open, in_progress, resolved, closed, reopened
    field :severity, :string # P1, P2, P3, P4
    field :assigned_to, :string
    field :playbook_id, :string
    field :workflow_id, :string
    field :detected_at, :utc_datetime
    field :resolved_at, :utc_datetime
    field :closed_at, :utc_datetime

    embeds_many :comments, Comment
    has_many :related_incidents, Incident

    timestamps()
  end
end
```

**Effort:** High
**Priority:** High (core feature)

---

### Story 5.5: Playbook editor

**As a system administrator,**
**I want to create and edit playbooks for incident remediation,**
**So that agents have standardized procedures to follow for common incident types.**

**Acceptance Criteria:**
- [ ] Playbook editor UI for creating playbook steps
- [ ] Playbooks define: workflow chain, agent-specific instructions, approval requirements
- [ ] Playbooks can be organized by incident type or service
- [ ] Playbook editor supports versioning (playbooks can be forked and updated)
- [ ] Playbooks can be previewed (test workflow without running agents)
- [ ] Playbooks can be shared with other users/teams
- [ ] Playbooks support variables (placeholders for dynamic values like service names)

**Technical Notes:**
- Use a rich text editor or markdown editor for agent instructions
- Playbook versioning tracks who made changes and when
- Playbook variables are interpolated at runtime (e.g., `{{service_name}}`)
- Playbooks can be imported/exported as JSON for sharing

**Playbook Schema:**
```elixir
defmodule AgentMonitor.Playbook do
  schema "playbooks" do
    field :name, :string
    field :description, :text
    field :incident_type, :string
    field :variables, {:array, :map} # [{name, default_value, description}]
    field :steps, {:array, :map} # [{agent_id, instructions, requires_approval}]
    field :version, :string
    field :is_active, :boolean

    belongs_to :author, User

    timestamps()
  end
end
```

**Playbook Editor UI:**
```elixir
# Step editor
[
  %{
    agent: "investigate_logs",
    instructions: "Check {{service_name}} logs for errors in the last hour",
    requires_approval: false
  },
  %{
    agent: "remediate_restart",
    instructions: "Restart {{service_name}} if errors persist",
    requires_approval: true
  }
]
```

**Effort:** High
**Priority:** Medium (standardization feature)

---

## Dependencies & Ordering

**Phase 4 Stories:**
- 4.1 (Agent chaining) → 4.2, 4.3, 4.4 (workflow engine is foundation)
- 4.2 (Conversation history) should be done early (critical for all workflows)
- 4.3 (Parallel execution) can be done after 4.1
- 4.4 (Human approval) can be done after 4.1
- 4.5 (Marketplace) is independent, can be done anytime

**Phase 5 Stories:**
- 5.1 (Phoenix LiveView) must be done first (UI foundation)
- 5.2, 5.3, 5.4 can be done in parallel after 5.1
- 5.5 (Playbook editor) is independent, can be done anytime after 5.1

---

## Effort Summary

| Phase | Stories | Total Effort |
|-------|---------|--------------|
| Phase 4 | 5 stories | ~5-6 days |
| Phase 5 | 5 stories | ~6-7 days |
| **Total** | **10 stories** | **~11-13 days** |

---

## Definition of Done

Each story is complete when:
1. All acceptance criteria pass
2. Code is reviewed (self or pair)
3. Ecto migrations are run and tested
4. LiveView components handle real-time updates correctly
5. Documentation is updated (if behavior changes)
6. Edge cases are considered (timeouts, failures, concurrent access)

---

**Ready to ralph! 🚀**
