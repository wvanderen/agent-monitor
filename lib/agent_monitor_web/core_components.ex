defmodule AgentMonitorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component
  import Phoenix.VerifiedRoutes

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button.
  """
  attr(:type, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(disabled form name value))

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-900">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.
  """
  attr(:id, :string, default: nil)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  slot :col, required: true do
    attr(:label, :string)
    attr(:class, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-left text-[0.8125rem] leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="pb-4 pt-11 pr-6 font-semibold uppercase tracking-wider">
              <%= col[:label] %>
            </th>
            <th :if={@action != []} class="relative pb-4 pt-11 pr-6">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={@row_click && "replace_list"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "cursor-pointer hover:bg-zinc-50"]}
            >
              <div class="block py-4 pr-6">
                <span class={["absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl", i == 0 && "sm:rounded-l-xl", i == length(@col) - 1 && "sm:rounded-r-xl"]}></span>
                <span class="relative [html>&>]:flex justify-between items-center">
                  <%= render_slot(col, row) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative whitespace-nowrap py-4 pl-3 pr-6 text-right text-sm font-medium sm:pr-6">
              <span class={["absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-r-xl"]}></span>
              <span class="relative flex justify-end">
                <%= render_slot(@action, row) %>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a list of badges.
  """
  attr(:badges, :list, required: true)

  def badge_list(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <%= for badge <- @badges do %>
        <span class="inline-flex items-center rounded-md bg-zinc-50 px-2 py-1 text-xs font-medium text-zinc-600 ring-1 ring-inset ring-zinc-500/10">
          <%= badge %>
        </span>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders navigation links.
  """
  def navigation_links(assigns) do
    ~H"""
    <nav class="border-b border-zinc-200 mb-8">
      <div class="flex gap-6 py-4">
        <a href="/" class="text-zinc-600 hover:text-zinc-900 font-medium">
          Dashboard
        </a>
        <a href="/incidents" class="text-zinc-600 hover:text-zinc-900 font-medium">
          Incidents
        </a>
        <a href="/workflows" class="text-zinc-600 hover:text-zinc-900 font-medium">
          Workflows
        </a>
        <a href="/playbooks" class="text-zinc-600 hover:text-zinc-900 font-medium">
          Playbooks
        </a>
        <a href="/marketplace" class="text-zinc-600 hover:text-zinc-900 font-medium">
          Marketplace
        </a>
      </div>
    </nav>
    """
  end
end
