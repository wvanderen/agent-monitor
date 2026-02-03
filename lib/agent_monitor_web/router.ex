defmodule AgentMonitorWeb.Router do
  use AgentMonitorWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AgentMonitorWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AgentMonitorWeb do
    pipe_through(:browser)

    live("/", DashboardLive, :index)
    live("/approvals", ApprovalLive, :index)
    live("/incidents", IncidentLive, :index)
    live("/incidents/:id", IncidentDetailLive, :show)
    live("/workflows", WorkflowLive, :index)
    live("/workflows/:id", WorkflowDetailLive, :show)
    live("/workflows/:workflow_id/diagram", WorkflowDiagramLive, :show)
    live("/playbooks", PlaybookLive, :index)
    live("/playbooks/:id/edit", PlaybookEditorLive, :edit)
    live("/marketplace", MarketplaceLive, :index)
    live("/conversations/:workflow_id", ConversationLive, :show)
  end

  scope "/api", AgentMonitorWeb do
    pipe_through(:api)

    post("/incidents", IncidentController, :create)
    put("/incidents/:id", IncidentController, :update)
    post("/approvals/:id/respond", ApprovalController, :respond)
  end
end
