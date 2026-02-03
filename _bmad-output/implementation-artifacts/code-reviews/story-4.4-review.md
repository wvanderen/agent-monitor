# Code Review Summary - Story 4.4

**Story:** 4.4 - Human-in-the-loop approval
**Review Date:** 2026-02-02
**Status:** ❌ IN_PROGRESS (8 issues found)

---

## Executive Summary

Story 4.4 has the **same fundamental problem as Story 4.3**: an approval system exists in isolation but is **completely disconnected from workflow execution**.

While ApprovalRequest schema and ApprovalController exist, they're never integrated into the actual agent execution flow. Agents run without ever needing or requesting approval.

**Key Findings:**
- **5 Critical Issues** - Core functionality missing or broken
- **2 Medium Issues** - Architectural problems
- **1 Low Issue** - Code quality improvement needed
- **0 Tests** - No test coverage for approval system

---

## Critical Issues (Must Fix Before Merging)

### 🔴 CRITICAL-1: Agents Cannot Request Approval
**File:** `lib/agent_monitor/workflow_engine.ex`
**Severity:** HIGH

REQ-4.4-1 requires "Agents can request human approval for sensitive actions" but there's **NO mechanism anywhere** for agents to request approval.

WorkflowEngine's `execute_agent_step` function (lines 187-206 in workflow_engine.ex) simply calls agents:
```elixir
defp execute_agent_step(workflow, agent_name, step_index) do
  context = build_agent_context(workflow, step_index)

  case execute_agent(agent_name, context) do
    {:ok, result} ->
      # Add conversation entry
      # Return result
    {:error, reason} ->
      {:error, reason}
  end
end
```

**NO approval checkpoint exists**. Agents execute immediately with no human oversight.

**Evidence of Missing Integration:**
```bash
$ grep -rn "ApprovalRequest" lib/agent_monitor/workflow_engine.ex
# ZERO results - WorkflowEngine never imports or uses ApprovalRequest!
```

**Required Action:**
```elixir
# In workflow_engine.ex, add approval checkpoint
defp execute_agent_step(workflow, agent_name, step_index) do
  # Check if action requires approval
  if requires_approval?(agent_name, context) do
    # Create approval request
    {:ok, approval} = ApprovalRequest.create_changeset(
      workflow.id,
      to_string(agent_name),
      "Some sensitive action",
      build_action_context(workflow, step_index),
      determine_risk_level(context),
      60  # expires_in_minutes
    )
    |> Repo.insert()

    # Block until approved
    case await_approval(approval.id) do
      :approved ->
        # Continue with execution
        execute_agent(agent_name, Map.put(context, :approval, approval))
      :rejected ->
        {:error, :approval_rejected}
      :expired ->
        {:error, :approval_expired}
    end
  else
    # No approval needed, execute directly
    execute_agent(agent_name, context)
  end
end
```

---

### 🔴 CRITICAL-2: No Notification Channels for Approvals
**File:** `lib/agent_monitor/workflow_engine.ex`, `lib/notifications/`
**Severity:** HIGH

REQ-4.4-2 requires "Approval requests are sent via configured channel (email, Slack, UI notification)" but approval requests are **NEVER sent via any channel**.

Email and Slack notification modules exist (`lib/notifications/channels/email.ex`, `lib/notifications/channels/slack.ex`) but are NEVER used for approvals:

```bash
$ grep -rn "send.*email\|send.*slack" lib/notifications/ --include="*.ex"
# They're used by Remediation module:
lib/remediation.ex:347:    Notifications.Dispatcher.send(notification, [:slack, :email])
lib/remediation.ex:361:    Notifications.Dispatcher.send(notification, [:slack])
lib/remediation.ex:373:    Notifications.Dispatcher.send(notification, [:slack, :email])

# BUT NEVER used for approval requests!
```

When approval is created (which doesn't happen since agents don't request approval), there's no notification dispatch.

**Required Action:**
```elixir
# In approval request creation (see CRITICAL-1), add notification
defp create_approval_request(workflow_id, agent_name, action, context) do
  # Create approval
  {:ok, approval} = ApprovalRequest.create_changeset(...) |> Repo.insert()

  # Send notifications via all configured channels
  notification = %{
    type: :approval_requested,
    approval_id: approval.id,
    agent: agent_name,
    action: action,
    risk_level: approval.risk_level
  }

  # Email notification
  Notifications.Channels.Email.send(%{
    to: Application.get_env(:agent_monitor, :approval_email),
    subject: "Approval Required: #{agent_name} action",
    body: """
    Agent #{agent_name} is requesting approval for:
    Action: #{action}
    Risk Level: #{approval.risk_level}
    Context: #{inspect(context)}

    Respond at: /approvals/#{approval.id}
    """
  })

  # Slack notification
  Notifications.Channels.Slack.send(%{
    webhook_url: Application.get_env(:agent_monitor, :slack_webhook),
    text: "Approval required: #{agent_name} - #{action}"
  })

  # PubSub UI notification
  Phoenix.PubSub.broadcast(AgentMonitor.PubSub, "approvals", {:new_approval, approval})

  {:ok, approval}
end
```

---

### 🔴 CRITICAL-3: No Approval UI
**File:** `lib/agent_monitor_web/`
**Severity:** HIGH

REQ-4.4-3 requires "Approval UI shows: agent action description, context, risk level, estimated impact" but there's **NO LiveView or page** for displaying pending approvals.

Only ApprovalController exists (`lib/agent_monitor_web/controllers/approval_controller.ex`) which handles approve/reject **RESPONSES** to approvals:
```elixir
def respond(conn, %{"id" => id, "action" => action, "user" => user}) do
  # This handles the USER'S RESPONSE to approve/reject
  # NOT displaying pending approvals!
end
```

There's **NO UI for users to see**:
- Pending approval requests
- Agent action details
- Context
- Risk level
- Estimated impact

**Evidence:**
```bash
$ find lib/agent_monitor_web -name "*approval*.ex" -type f
lib/agent_monitor_web/controllers/approval_controller.ex

$ find lib/agent_monitor_web -name "*approval*.ex" -type f -name "*live*"
# NO LIVEVIEW FILES FOR APPROVALS!
```

**Required Action:**
```elixir
# lib/agent_monitor_web/live/approval_live.ex
defmodule AgentMonitorWeb.ApprovalLive do
  use AgentMonitorWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    approval = AgentMonitor.Repo.get!(AgentMonitor.ApprovalRequest, id)

    {:ok, assign(socket, :approval, approval)}
  end

  def render(assigns) do
    ~H"""
    <.container>
      <.header>
        Approval Required
      </.header>

      <.content>
        <div class="action-section">
          <h2>Agent Action</h2>
          <p><%= @approval.action %></p>
        </div>

        <div class="context-section">
          <h2>Context</h2>
          <pre><%= inspect(@approval.context) %></pre>
        </div>

        <div class="risk-section">
          <h2>Risk Assessment</h2>
          <p>Risk Level: <span class={"risk-#{@approval.risk_level}"}><%= @approval.risk_level %></span></p>
          <!-- Missing: estimated_impact field -->
        </div>
      </.content>

      <.actions>
        <button phx-click="approve" class="approve-button">
          Approve
        </button>

        <button phx-click="reject" class="reject-button">
          Reject
        </button>

        <button phx-click="approve_with_modifications" class="modify-button">
          Approve with Modifications
        </button>
      </.actions>
    </.container>
    """
  end

  def handle_event("approve", _params, socket) do
    # Call approval controller
    socket
    |> redirect_to("http://localhost:4000/api/approvals/#{@approval.id}/respond?action=approve&user=#{socket.assigns.current_user}")
  end
end
```

---

### 🔴 CRITICAL-4: No Whitelist/Pre-Approval Mechanism
**File:** (MISSING)
**Severity:** HIGH

REQ-4.4-7 requires "Approval can be pre-approved for certain agents or incident types (whitelist)" but this functionality is **COMPLETELY MISSING** from the codebase:

```bash
$ find lib/agent_monitor -name "*whitelist*.ex"
# NO FILES FOUND!

$ grep -rn "whitelist\|pre.*approve" lib/agent_monitor/
# NO RESULTS!
```

No ApprovalWhitelist table exists in migrations. No whitelist checking logic exists anywhere.

**Impact:** Cannot skip approval for trusted agents or low-risk actions as specified in requirements.

**Required Action:**
1. Create migration:
```elixir
# priv/repo/migrations/XXXXXXXXXX_create_approval_whitelists.exs
def change do
  create table(:approval_whitelists, primary_key: false) do
    add(:id, :binary_id, primary_key: true)
    add(:agent_id, :string)
    add(:incident_type, :string)
    add(:risk_level_threshold, Ecto.Enum, values: [:low, :medium, :high, :critical])
    add(:requires_approval, :boolean, default: true)
    add(:notes, :string)
    add(:created_by, :string)

    timestamps()
  end

  create(index(:approval_whitelists, [:agent_id]))
  create(index(:approval_whitelists, [:incident_type]))
  create(index(:approval_whitelists, [:risk_level_threshold]))
end
```

2. Create schema:
```elixir
defmodule AgentMonitor.ApprovalWhitelist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "approval_whitelists" do
    field(:agent_id, :string)
    field(:incident_type, :string)
    field(:risk_level_threshold, Ecto.Enum, values: [:low, :medium, :high, :critical])
    field(:requires_approval, :boolean, default: true)
    field(:notes, :string)
    field(:created_by, :string)

    timestamps()
  end
end
```

3. Add whitelist checking:
```elixir
defmodule ApprovalRequest do
  def check_whitelist(agent_id, incident_type, risk_level) do
    query = from(w in ApprovalWhitelist,
      where: w.agent_id == ^agent_id,
      where: is_nil(w.incident_type) or w.incident_type == ^incident_type,
      where: is_nil(w.risk_level_threshold) or w.risk_level_threshold >= ^risk_level
    )

    case Repo.one(query) do
      nil -> :requires_approval
      %{requires_approval: false} -> :skip_approval
    end
  end
end
```

---

### 🔴 CRITICAL-5: Zero Test Coverage
**File:** `test/`
**Severity:** HIGH

There are **ZERO tests** for:
- ApprovalRequest schema validation
- ApprovalController approve/reject logic
- Approval workflow integration
- Whitelist checking
- Notification sending for approvals
- Expiry handling
- Approval UI (if/when created)

**Impact:** No confidence approval system works correctly. Since it's never integrated into workflows, tests would reveal integration issues.

**Required Action:**
```elixir
# test/agent_monitor/approval_request_test.exs
defmodule AgentMonitor.ApprovalRequestTest do
  use AgentMonitor.DataCase

  alias AgentMonitor.ApprovalRequest

  test "create_changeset creates valid approval" do
    # Test
  end

  test "expires_at is calculated correctly" do
    # Test
  end

  test "is_expired? returns correct status" do
    # Test
  end
end

# test/agent_monitor_web/approval_controller_test.exs
defmodule AgentMonitorWeb.ApprovalControllerTest do
  use AgentMonitorWeb.ConnCase

  test "respond approves approval request" do
    # Test
  end

  test "respond rejects approval request with reason" do
    # Test
  end

  test "respond with modifications updates approval" do
    # Test
  end
end
```

---

## Medium Issues (Should Fix)

### 🟡 MEDIUM-1: WorkflowEngine Doesn't Integrate Approvals
**File:** `lib/agent_monitor/workflow_engine.ex`
**Severity:** MEDIUM

The entire approval system (schema + controller) is completely disconnected from workflow execution:

```bash
$ grep -rn "ApprovalRequest\|approval" lib/agent_monitor/workflow_engine.ex
# ZERO IMPORTS OR USAGE OF APPROVAL REQUEST!
```

WorkflowEngine runs agents without ever:
- Checking for pending approvals
- Blocking execution until approved
- Notifying agents of approval status

**Impact:** Approval system exists but is never used. This is worse than not implemented - it's code that's completely irrelevant to the running system.

**Required Action:** See CRITICAL-1 for integration example.

---

### 🟡 MEDIUM-2: Missing Estimated Impact Field
**File:** `lib/agent_monitor/approval_request.ex:8-23`
**Severity:** MEDIUM

Story requirements specify UI should show "estimated impact of action" (REQ-4.4-3) but ApprovalRequest schema has **NO such field**:

```elixir
defmodule AgentMonitor.ApprovalRequest do
  schema "approval_requests" do
    field(:agent_id, :string)
    field(:action, :string)
    field(:status, Ecto.Enum, values: [:pending, :approved, :rejected, :expired])
    field(:context, :map, default: %{})
    field(:risk_level, Ecto.Enum, values: [:low, :medium, :high, :critical])
    field(:expires_at, :utc_datetime)
    field(:approved_by, :string)
    field(:approved_at, :utc_datetime)
    field(:rejection_reason, :string)
    field(:modifications, :map)

    # NO estimated_impact field!
  end
end
```

**Impact:** Cannot fulfill REQ-4.4-3 fully. UI cannot display estimated impact.

**Required Action:**
```elixir
# Add to schema
field(:estimated_impact, :text)

# Update migration
add(:estimated_impact, :text)

# In approval request creation
defp create_approval_request(workflow, agent_name, action, context) do
  impact = estimate_action_impact(action, context)

  {:ok, approval} = ApprovalRequest.create_changeset(
    workflow.id,
    agent_name,
    action,
    Map.put(context, :estimated_impact, impact),
    risk_level,
    60
  )
  |> Repo.insert()

  {:ok, approval}
end

defp estimate_action_impact(action, context) do
  # Implement impact estimation logic
  # Could be LLM-based or rule-based
  case action do
    "restart_service" -> "Service restart will cause ~30s downtime"
    "scale_up" -> "Scaling up will increase costs by ~20%"
    _ -> "Unknown impact"
  end
end
```

---

## Low Issues (Nice to Fix)

### 🟢 LOW-1: No Auto-Expiry Checking
**File:** `lib/agent_monitor/approval_request.ex`, `lib/agent_monitor_web/controllers/approval_controller.ex`
**Severity:** LOW

Schema has `expires_at` field and `is_expired?` helper (approval_request.ex:92-94) but there's **NO background process** to check for expired approvals and auto-reject them.

The only expiry check is manual in ApprovalController:
```elixir
def respond(conn, %{"id" => id, "action" => action, "user" => user}) do
  approval = AgentMonitor.Repo.get!(AgentMonitor.ApprovalRequest, id)

  if AgentMonitor.ApprovalRequest.is_expired?(approval) do
    # Manual expiry check - expires but doesn't auto-reject!
    AgentMonitor.Repo.update(AgentMonitor.ApprovalRequest.expire_changeset(approval))
    # Returns error to API call, but approval still shows as pending
    {:ok, _} =
      AgentMonitor.Repo.update(AgentMonitor.ApprovalRequest.expire_changeset(approval))

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Approval request has expired"})
  else
    # Process approval...
  end
end
```

REQ-4.4-5 requires "Auto-reject approval when timeout reached" which implies **automatic background checking**, not manual.

**Required Action:**
```elixir
# Create background process
defmodule AgentMonitor.ApprovalExpiryWorker do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, _opts, name: __MODULE__)
  end

  def init(_opts) do
    # Check every minute
    schedule_expiry_check(60_000)
    {:ok, %{}}
  end

  def handle_info(:check_expired, state) do
    expired_approvals =
      AgentMonitor.Repo.all(
        from(a in ApprovalRequest,
          where: a.status == :pending and a.expires_at < ^DateTime.utc_now())
        )
      )

    Enum.each(expired_approvals, fn approval ->
      Logger.info("Auto-rejecting expired approval: #{approval.id}")

      AgentMonitor.Repo.update(ApprovalRequest.expire_changeset(approval))

      # Notify agent of rejection
      Phoenix.PubSub.broadcast(AgentMonitor.PubSub, "approvals", {:approval_expired, approval})
    end)

    schedule_expiry_check(60_000)
    {:noreply, state}
  end

  defp schedule_expiry_check(interval) do
    Process.send_after(self(), :check_expired, interval)
  end
end
```

---

## Requirement Status Summary

| ID | Requirement | Status | Notes |
|-----|-------------|---------|--------|
| REQ-4.4-1 | Agents can request approval | NOT_IMPLEMENTED | Schema exists but NO mechanism for agents to request approval. WorkflowEngine doesn't integrate approval system |
| REQ-4.4-2 | Sent via configured channels | NOT_IMPLEMENTED | Email and Slack modules exist but NEVER used for approvals. No notification dispatch when approval requested |
| REQ-4.4-3 | Approval UI shows details | NOT_IMPLEMENTED | NO LiveView exists. Only ApprovalController for approve/reject RESPONSES. No UI for displaying pending approvals |
| REQ-4.4-4 | Approve/reject/with modifications | PARTIAL | approve/reject changesets exist, but approvals only created/approved via API, not triggered by agents during workflow execution |
| REQ-4.4-5 | Time-boxed with auto-reject | PARTIAL | Schema has expires_at and is_expired helper, but NO background process to auto-reject. Only manual expiry check in controller |
| REQ-4.4-6 | Approval history logged | PARTIAL | Schema has approved_by and approved_at fields, and approve_changeset sets them, but no separate audit log exists |
| REQ-4.4-7 | Pre-approval whitelist | NOT_IMPLEMENTED | COMPLETELY MISSING. NO whitelist table, no whitelist schema, no whitelist checking logic |

---

## Recommendations

### Immediate Actions (Before Story Considered Complete)
1. **Integrate approval system into WorkflowEngine** - Add approval checkpoint to `execute_agent_step`. Block execution until approved.
2. **Create approval UI** - Build ApprovalLive LiveView to display pending approvals.
3. **Implement notification channels** - Dispatch email, Slack, and PubSub notifications when approval is requested.
4. **Create whitelist mechanism** - Add ApprovalWhitelist schema and checking logic.
5. **Add comprehensive test suite** - Tests for approval requests, controller, expiry, whitelist.

### Short-term Improvements
6. **Add estimated_impact field** to schema and implement impact estimation logic.
7. **Implement auto-expiry background process** - Use GenServer to check and auto-reject expired approvals.
8. **Add approval history query** - Separate audit log or query function.

### Long-term Improvements
9. **Design approval workflow visualization** - Show approval status in workflow diagram.
10. **Add approval templates** - Pre-defined approval scenarios for common actions.
11. **Implement approval delegation** - Allow approval to be delegated to other users.
12. **Add approval analytics** - Track approval times, rejection rates, common reasons.

---

## Files Changed (Git Status)

Modified:
- `lib/agent_monitor/application.ex` - Added ApprovalRequest association to Workflow schema

Untracked (New):
- `lib/agent_monitor/approval_request.ex`
- `lib/agent_monitor_web/controllers/approval_controller.ex`
- `priv/repo/migrations/20240202120003_create_approval_requests.exs`

---

## Conclusion

Story 4.4 is **NOT READY** for completion. The approval system has the same fundamental problem as Story 4.3: it exists in code but is **completely disconnected from actual workflow execution**.

The most critical issues are:
1. **Agents cannot request approval** - No mechanism exists in WorkflowEngine
2. **No notifications** - Email and Slack modules never used for approvals
3. **No UI** - Only controller for responses, no page to see pending approvals
4. **Whitelist missing** - COMPLETELY absent from codebase

This is worse than not implemented - it's dead code that wastes implementation effort. The schema and controller exist but are never used because the integration point with WorkflowEngine is missing.

**Recommendation:** Mark story as "in-progress" and prioritize integrating approval system into WorkflowEngine execution flow. Without this integration, the entire approval feature is non-functional.

---

**Generated by:** AI Code Reviewer (Adversarial)
**Date:** 2026-02-02
**Review ID:** CODE-REVIEW-4.4-001
