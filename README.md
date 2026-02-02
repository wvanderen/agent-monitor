# Agent Monitor 🐱

A concurrent, fault-tolerant service monitor built with Elixir. Demonstrates why the BEAM VM is perfect for AI agent orchestration.

## What Makes This Special?

This isn't just another monitoring tool. It's a demonstration of **Elixir's superpower for AI agents**:

- ✅ **True Concurrency**: Each endpoint runs in its own process — no thread pools, no async/await complexity
- ✅ **Let It Crash**: If any checker crashes, the supervisor automatically restarts it
- ✅ **Fault Isolation**: One failing endpoint can't take down the rest
- ✅ **Hot Reloading**: Add/remove endpoints without restarting the app
- ✅ **Scalable**: Monitor hundreds of endpoints with minimal overhead

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
Monitor.Supervisor (Root)
├── Monitor.Registry (Process naming)
├── Monitor.Coordinator (Aggregates results)
└── Monitor.CheckerSupervisor (Dynamic)
    └── Monitor.EndpointChecker (Per URL)
    └── Monitor.EndpointChecker (Per URL)
    └── ...
```

### Key Components

- **EndpointChecker**: Independent process that monitors a single URL
- **Coordinator**: Central hub collecting results and triggering alerts
- **Supervisor**: Ensures all processes stay alive (automatic restarts)

## Next Steps (Homework!)

Now that you have the basics running, try:

1. **Experiment with concurrency**: Add 20+ endpoints and watch it handle them effortlessly
2. **Test fault tolerance**: Find an endpoint checker PID and kill it — watch it auto-restart
3. **Add intelligent recovery**: Hook the coordinator up to an LLM to suggest fixes
4. **Build a dashboard**: Use Phoenix LiveView for real-time visualization

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
