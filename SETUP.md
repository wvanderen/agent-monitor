# Agent Monitor

## Setup

1. Install dependencies:
   ```bash
   mix deps.get
   ```

2. Create and setup the database:
   ```bash
   mix ecto.create
   mix ecto.migrate
   mix run priv/repo/seeds.exs
   ```

3. Install assets:
   ```bash
   cd assets && npm install
   ```

4. Start the server:
   ```bash
   mix phx.server
   ```

Visit `http://localhost:4000` to see the dashboard.

## Features Implemented

### Phase 4: Multi-Agent Workflows

- ✅ Workflow Ecto schema with fields: incident_id, status, current_step, steps, context
- ✅ WorkflowEngine module for sequential agent chaining
- ✅ Default workflow chain: monitor_agent → investigate_agent → remediate_agent → verify_agent
- ✅ Output passing between sequential agents
- ✅ Workflow state transitions (pending -> in_progress -> completed/failed)
- ✅ Conversation Ecto schema with workflow_id, agent_id, role, content, metadata, embedding
- ✅ ConversationManager module for conversation history management
- ✅ ContextVersion Ecto schema for immutable snapshots
- ✅ Context versioning with immutable snapshots for each workflow step
- ✅ ParallelExecutor module for parallel agent execution
- ✅ Support for concurrent branches in workflow DAG
- ✅ Result aggregation at convergence points
- ✅ Fault isolation for parallel agent branches
- ✅ ApprovalRequest Ecto schema for human-in-the-loop approval
- ✅ Approval workflow with time-boxed expiration
- ✅ Incident Ecto schema with status, severity, assignee fields
- ✅ Incident state machine (open, in_progress, resolved, closed, reopened)
- ✅ Severity levels: P1 (critical), P2 (high), P3 (medium), P4 (low)
- ✅ Playbook Ecto schema with workflow chain and variables
- ✅ Playbook variables support with {{variable_name}} syntax

### Phase 5: Dashboard

- ✅ Phoenix LiveView setup for real-time UI
- ✅ DashboardLive view with real-time metrics
- ✅ Incident list view with filtering
- ✅ Workflow list view with status tracking
- ✅ Playbook editor UI
- ✅ Agent marketplace UI
- ✅ Conversation view with agent color coding
- ✅ Pub/sub for efficient updates (no polling)
- ✅ API controllers for incident and approval management

## Development

- Run tests: `mix test`
- Start IEx with app loaded: `iex -S mix`
- Format code: `mix format`
- Check code quality: `mix compile --warnings-as-errors`
