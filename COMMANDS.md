# Agent Monitor Commands Reference

## Quick Reference

| Command | Description |
|---------|-------------|
| `Monitor.Console.status()` | Show all endpoint status |
| `Monitor.Console.add(url)` | Add a new endpoint |
| `Monitor.Console.remove(url)` | Remove an endpoint |
| `Monitor.Console.check(url)` | Trigger immediate check |
| `Monitor.Console.list()` | List all endpoints |
| `Monitor.Console.history(url)` | Show check history |

## Starting the Monitor

### Interactive Mode (Best for Exploration)
```bash
iex -S mix
```
Then run commands directly in the IEx console.

### Background Mode (Production)
```bash
mix run --no-halt &
```
Monitor runs in the background. Use `iex --remote` to connect.

## Common Workflows

### Add and Monitor a New Endpoint
```elixir
Monitor.Console.add("https://api.github.com")
# Wait 30 seconds for first scheduled check
Monitor.Console.status()
```

### Test Multiple Endpoints
```elixir
["https://api.github.com", "https://httpbin.org/delay/2", "https://example.com"]
|> Enum.each(&Monitor.Console.add/1)

Monitor.Console.status()
```

### Check History of a Specific Endpoint
```elixir
Monitor.Console.history("https://api.github.com")
```

## Understanding the Output

### Status Display
```
🟢 UP https://api.github.com
   Checks: 5 | Failures: 0
   Last: ok HTTP 200
   Duration: 243ms
```

- **🟢 UP**: Endpoint is healthy (responding with 2xx/3xx)
- **🔴 DOWN**: Endpoint is unhealthy (error or 4xx/5xx)
- **Checks**: Total number of checks performed
- **Failures**: Consecutive failures detected
- **Duration**: Last request time in milliseconds

## Advanced Usage

### Find the PID of an Endpoint Checker
```elixir
# Note: Checkers are now unnamed (simplified architecture)
# Use the Coordinator to track results instead
Monitor.Coordinator.get_result("https://example.com")
```

### Test Fault Tolerance
```elixir
# Find a checker process and kill it
# It will auto-restart via the supervisor
```

### Custom Check Intervals
Edit `lib/agent_monitor/application.ex` to change `check_interval` (default: 30_000ms = 30 seconds).

## Troubleshooting

### "No endpoints monitored yet"
The monitor starts with default endpoints but checks run on a 30s schedule. Either:
1. Wait ~30 seconds after starting
2. Add your own endpoints with `Monitor.Console.add(url)`

### Endpoint not showing up after adding
Check the logs for errors:
```elixir
# Start the application and watch logs
mix run --no-halt
```

### Want faster check intervals?
Edit `lib/agent_monitor/application.ex`:
```elixir
check_interval: 10_000  # Change to 10 seconds
```

Then recompile:
```bash
mix compile
```
