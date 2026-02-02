# 🎓 Code Tour for Lem

Welcome to your first Elixir project! Here's what you're looking at.

## The Big Picture

Elixir is built on the **BEAM VM**, which is:
- Concurrent (runs many things at once, truly)
- Fault-tolerant (processes crash and restart automatically)
- Distributed (processes can be on different machines)

## File Breakdown

### 1. `lib/monitor/endpoint_checker.ex` 📡
**What it does**: Monitors a single URL every N seconds

**Key Elixir concepts**:
- `GenServer` — A standard pattern for processes with state
- `handle_info/2` — Reacts to messages (like our timer tick)
- `Registry` — Namespaced process lookup (find processes by URL)

**Watch for**:
- Each checker has its own state, completely isolated from others
- If it crashes, the supervisor restarts it automatically

### 2. `lib/monitor/coordinator.ex` 🎯
**What it does**: Collects results from all checkers

**Key Elixir concepts**:
- Message passing — Checkers `send(coordinator, {:check_result, ...})`
- No shared state — Data flows via messages, not shared variables
- Aggregation pattern — Building a view from many sources

**Watch for**:
- How it receives messages from processes all over the system
- No locking, no race conditions — messages are queued automatically

### 3. `lib/monitor/supervisor.ex` 🛡️
**What it does**: Manages the entire monitoring system

**Key Elixir concepts**:
- **"Let it crash"** philosophy — Don't prevent crashes, handle them
- `DynamicSupervisor` — Can add/remove children at runtime
- One-for-one strategy — If a child dies, restart that one only

**Watch for**:
- How it auto-restarts crashed processes
- Hot code reloading possible (add endpoints without restart)

### 4. `lib/agent_monitor/application.ex` 🚀
**What it does**: Entry point for the OTP application

**Key Elixir concepts**:
- Supervision tree — Hierarchical process management
- Children list — Declarative process setup

### 5. `lib/monitor_console.ex` 💻
**What it does**: Friendly commands for you to interact with the system

**Key Elixir concepts**:
- Pattern matching in function heads (`def add(url)`)
- Pipe operator for data flow (not used here, but you'll see it)
- Interactive IEx development

## The Magic You're Seeing

### Concurrency Without Threads
```elixir
# This spawns 1000 independent processes
urls |> Enum.map(fn url ->
  spawn(fn -> monitor_url(url) end)
end)
```

Each runs on its own CPU core (if available). No thread pool management.

### Fault Tolerance Without Try/Catch
```elixir
# If this crashes:
def handle_info(:check, state) do
  result = HTTPoison.get(url)  # This might fail!
  # Supervisor restarts the process from init/1
end
```

### Message Passing
```elixir
# Send a message to any process
send(coordinator, {:check_result, url, result})

# Receive it on the other side
def handle_info({:check_result, url, result}, state) do
  # Handle it
end
```

## Homework to Reinforce

### Easy (Do this first)
1. Run `./start.sh` and try the commands in README
2. Add an endpoint that will fail: `Monitor.Console.add("https://thisdoesnotexist12345.com")`
3. Kill a process manually and watch it restart:
   ```elixir
   # Find the PID of an endpoint checker
   [{pid, _}] = Registry.lookup(Monitor.Registry, {:endpoint_checker, "https://example.com"})
   Process.exit(pid, :kill)
   # Watch logs — it auto-restarts!
   ```

### Medium
1. Change the check interval for a specific endpoint
2. Add a counter that tracks total uptime percentage
3. Store results in ETS (in-memory table) for faster queries

### Advanced
1. Hook the coordinator up to an LLM for intelligent alert routing
2. Build a Phoenix LiveView dashboard (real-time web UI)
3. Make it distributed: run multiple nodes and share the monitoring load

## Pattern Matching Is Your Friend

You'll see this everywhere in Elixir:

```elixir
# Function heads match different patterns
def handle_call(:get_results, _from, state) do
  # Match :get_results atom
end

def handle_call({:get_result, url}, _from, state) do
  # Match a tuple with :get_result and url
end

# Also works with case statements
case result do
  {:ok, data} -> # Happy path
  {:error, reason} -> # Error path
end
```

This is how Elixir avoids if/else soup. Think of it as "data-driven control flow".

## Next Step: Build Something

Once you understand these basics, you're ready to:
1. Replace `HTTPoison.get()` with an LLM call
2. Add tool use (email alerts, Slack notifications)
3. Build multi-agent workflows (coordinator → AI → action)

You now have the foundation for serious AI agent orchestration. 🎉
