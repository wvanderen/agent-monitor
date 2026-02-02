# Test long-running scheduled checks

IO.puts("Starting wait for scheduled checks (30s interval)...")
IO.puts("This will take about 32 seconds...\n")

Process.sleep(32_000)

IO.puts("\n=== After 30+ seconds ===")
Monitor.Console.status()
