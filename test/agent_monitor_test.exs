defmodule AgentMonitorTest do
  use ExUnit.Case
  doctest AgentMonitor

  test "greets the world" do
    assert AgentMonitor.hello() == :world
  end
end
