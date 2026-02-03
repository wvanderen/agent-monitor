# Agent Monitor 🐱

A concurrent, fault-tolerant service monitor with AI agent orchestration built with Elixir. Demonstrates why the BEAM VM is perfect for multi-agent AI systems.

## What Makes This Special?

This isn't just another monitoring tool. It's a production-ready **AI agent orchestration platform**:

- ✅ **True Concurrency**: Each endpoint and agent runs in its own process — no thread pools, no async/await complexity
- ✅ **Agent Chaining**: Monitor → Investigate → Remediate → Verify workflow execution
- ✅ **Parallel Execution**: Support for DAG-based parallel agent workflows with fault isolation
- ✅ **Let It Crash**: If any checker crashes, the supervisor automatically restarts it
- ✅ **Fault Isolation**: One failing endpoint can't take down the rest
- ✅ **Hot Reloading**: Add/remove endpoints and agents without restarting the app
- ✅ **Scalable**: Monitor hundreds of endpoints with minimal overhead
- ✅ **Conversation History**: Full context management across agent interactions
- ✅ **Human-in-the-Loop**: Approval workflows for sensitive remediation actions

## Quick Start

### Interactive Mode (Recommended)

```bash
cd agent_monitor
iex -S mix
```

Then in the IEx console:

```elixir
# Start the console helper
Monitor.Console.start()

# Check all endpoints
Monitor.Console.status()

# Add a new endpoint
Monitor.Console.add("https://api.github.com")

# Trigger an immediate check
Monitor.Console.check("https://api.github.com")

# View check history
Monitor.Console.history("https://api.github.com")

# Remove an endpoint
Monitor.Console.remove("https://api.github.com")

# List all monitored endpoints
Monitor.Console.list()
```

### One-Shot Mode

Run a single check without entering IEx:

```bash
# Run the test script (waits 30s for scheduled checks)
./start.sh

# Or run specific commands
mix run -e "Monitor.Console.status()"
mix run -e "Monitor.Console.add(\"https://api.github.com\")"
```

## Architecture

```
AgentMonitor.Supervisor (Root)
├── Monitor.Registry (Process naming)
├── Monitor.Coordinator (Aggregates results)
├── Monitor.CheckerSupervisor (Dynamic)
│   └── Monitor.EndpointChecker (Per URL)
├── AgentMonitor.WorkflowEngine (Agent orchestration)
├── AgentMonitor.ConversationManager (Context management)
├── AgentMonitor.ParallelExecutor (Parallel workflows)
└── TaskSupervisor (Agent execution)
```

### Key Components

- **EndpointChecker**: Independent process that monitors a single URL
- **WorkflowEngine**: Orchestrates agent workflows (sequential and parallel)
- **ConversationManager**: Manages conversation history and context across agents
- **ParallelExecutor**: Handles parallel agent execution with result aggregation
- **Coordinator**: Central hub collecting results and triggering alerts
- **Supervisor**: Ensures all processes stay alive (automatic restarts)

### Agent Types

- **MonitorAgent**: Monitors endpoints and detects anomalies
- **InvestigateAgent**: Performs root cause analysis using LLM
- **RemediateAgent**: Executes automated fixes (with approval workflow)
- **VerifyAgent**: Verifies remediation success

## Web Interface

The platform includes a Phoenix LiveView dashboard for real-time monitoring and management:

### Dashboard
- Real-time workflow monitoring
- Incident tracking with severity levels
- Agent status and uptime metrics

### Conversations
- Chat-style interface for agent interactions
- Filter by agent, time range, and keywords
- Full conversation history with context

### Incidents
- Create and manage incidents
- Attach files and add comments
- Assign incidents to team members
- Track incident lifecycle (open → in_progress → resolved → closed)

### Playbooks
- Create and edit incident response playbooks
- Define agent workflows with steps
- Configure approval requirements
- Export playbooks as JSON

### Approval System
- Review pending remediation approvals
- Approve or reject actions with reason
- Email notifications for approval requests

## Agent Workflow Features

### Sequential Execution
Default workflow chain: `monitor_agent → investigate_agent → remediate_agent → verify_agent`

- Output from each agent passes as input to the next
- Automatic retry on agent failure
- Configurable timeout handling

### Parallel Execution
- Support for DAG-based parallel workflows
- Independent branches with isolated contexts
- Result aggregation at convergence points
- Fault isolation - one branch failure doesn't stop others

### Context Management
- Full conversation history access for all agents
- Context includes: previous outputs, incident data, system state, user inputs
- Immutable snapshots for each workflow step
- Token-aware summarization for long conversations

### Human-in-the-Loop
- Agents can request approval for sensitive actions
- Risk assessment based on agent type and context
- Approval whitelist for trusted operations
- Automatic expiry for pending approvals

## Next Steps

Now that you have the platform running, try:

1. **Experiment with concurrency**: Add 20+ endpoints and watch it handle them effortlessly
2. **Test fault tolerance**: Find an endpoint checker PID and kill it — watch it auto-restart
3. **Create a parallel workflow**: Define a playbook with parallel branches
4. **Test approval workflow**: Configure an agent to require approval
5. **Build custom agents**: Add new agent types following the `execute/1` interface

## Learning Resources

- [Elixir Getting Started](https://elixir-lang.org/getting-started/introduction.html)
- [Learn Elixir in Y Minutes](https://learnxinyminutes.com/docs/elixir/)
- [BEAM VM Explained](https://www.youtube.com/watch?v=XJyN2p8hK3I)

## What You're Seeing

This is the foundation for **AI agent orchestration**. Each `EndpointChecker` is essentially a simple agent. Replace the HTTP check with an LLM call + tool use, and you've got:

- Parallel tool-calling agents
- Self-healing systems
- Stateful conversations that survive crashes
- Infinite scalability

Welcome to the future of agent systems. 🚀
