defmodule AgentMonitorWeb.JSONErrorView do
  use AgentMonitorWeb, :html

  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end
end
