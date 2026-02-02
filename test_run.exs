# Test script for agent monitor

# Wait for scheduled checks
IO.puts("Waiting 35 seconds for initial checks...")
Process.sleep(35_000)

IO.puts("\n=== Endpoint Status ===")
Monitor.Console.status()
