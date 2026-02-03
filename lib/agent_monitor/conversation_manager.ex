defmodule AgentMonitor.ConversationManager do
  @moduledoc """
  Manages conversation history and context for workflows.
  """

  use GenServer
  require Logger

  alias AgentMonitor.Conversation

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_conversation_history(workflow_id, opts \\ []) do
    GenServer.call(__MODULE__, {:get_history, workflow_id, opts})
  end

  def add_message(workflow_id, agent_id, role, content, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:add_message, workflow_id, agent_id, role, content, metadata})
  end

  def summarize_conversation(workflow_id) do
    GenServer.call(__MODULE__, {:summarize, workflow_id})
  end

  def search_conversations(workflow_id, query, opts \\ []) do
    GenServer.call(__MODULE__, {:search, workflow_id, query, opts})
  end

  @doc """
  Estimate token count for a given text.
  This is a simple approximation - in production, integrate with actual LLM tokenizer.
  """
  def estimate_token_count(text) when is_binary(text) do
    words = String.split(text)
    length(words)
  end

  def estimate_token_count(_), do: 0

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting ConversationManager")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_history, workflow_id, opts}, _from, state) do
    import Ecto.Query

    query = from(c in Conversation, where: c.workflow_id == ^workflow_id)

    query =
      cond do
        opts[:agent_id] ->
          where(query, [c], c.agent_id == ^opts[:agent_id])

        opts[:role] ->
          where(query, [c], c.role == ^opts[:role])

        opts[:time_start] && opts[:time_end] ->
          where(
            query,
            [c],
            c.inserted_at >= ^opts[:time_start] and c.inserted_at <= ^opts[:time_end]
          )

        true ->
          query
      end

    query = order_by(query, [c], asc: c.inserted_at)

    conversations = AgentMonitor.Repo.all(query)

    {:reply, conversations, state}
  end

  @impl true
  def handle_call({:add_message, workflow_id, agent_id, role, content, metadata}, _from, state) do
    token_count = estimate_token_count(content)

    changeset =
      %Conversation{}
      |> Conversation.changeset(%{
        workflow_id: workflow_id,
        agent_id: agent_id,
        role: role,
        content: content,
        metadata: metadata,
        tokens: token_count
      })

    case AgentMonitor.Repo.insert(changeset) do
      {:ok, conversation} ->
        {:reply, {:ok, conversation}, state}

      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end

  @impl true
  def handle_call({:summarize, workflow_id}, _from, state) do
    conversations = get_conversation_history(workflow_id)

    if length(conversations) > 10 do
      # Create summary
      summary_text = generate_summary(conversations)

      # Get message IDs to summarize
      message_ids = Enum.map(conversations, & &1.id)

      summary_changeset =
        Conversation.summary_changeset(workflow_id, summary_text, message_ids)

      case AgentMonitor.Repo.insert(summary_changeset) do
        {:ok, summary} ->
          {:reply, {:ok, summary}, state}

        {:error, changeset} ->
          {:reply, {:error, changeset}, state}
      end
    else
      {:reply, {:error, :too_short}, state}
    end
  end

  @impl true
  def handle_call({:search, workflow_id, query, opts}, _from, state) do
    conversations = get_conversation_history(workflow_id)

    results =
      Enum.filter(conversations, fn conv ->
        matches_search?(conv, query, opts)
      end)

    {:reply, results, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private Functions

  @max_context_tokens 4096

  defp generate_summary(conversations) do
    total_tokens = calculate_total_tokens(conversations)

    if total_tokens > @max_context_tokens do
      create_summary_with_token_counting(conversations)
    else
      create_simple_summary(conversations)
    end
  end

  defp calculate_total_tokens(conversations) do
    conversations
    |> Enum.map(&count_tokens/1)
    |> Enum.sum()
  end

  defp count_tokens(conversation) do
    content_tokens = estimate_token_count(conversation.content || "")
    conversation.tokens || content_tokens
  end

  defp create_simple_summary(conversations) do
    by_agent = Enum.group_by(conversations, & &1.agent_id)

    agent_summaries =
      Enum.map(by_agent, fn {agent_id, messages} ->
        message_count = length(messages)
        last_message = List.last(messages)

        %{
          agent_id: agent_id,
          message_count: message_count,
          last_activity: last_message.inserted_at,
          summary: "Agent #{agent_id} contributed #{message_count} messages"
        }
      end)

    "Conversation summary: #{inspect(agent_summaries)}"
  end

  defp create_summary_with_token_counting(conversations) do
    by_agent = Enum.group_by(conversations, & &1.agent_id)

    agent_summaries =
      Enum.map(by_agent, fn {agent_id, messages} ->
        message_count = length(messages)
        total_agent_tokens = messages |> Enum.map(&count_tokens/1) |> Enum.sum()
        last_message = List.last(messages)

        %{
          agent_id: agent_id,
          message_count: message_count,
          estimated_tokens: total_agent_tokens,
          last_activity: last_message.inserted_at,
          summary: summarize_agent_messages(agent_id, messages, total_agent_tokens)
        }
      end)

    total_messages = length(conversations)
    total_tokens = conversations |> Enum.map(&count_tokens/1) |> Enum.sum()

    "Conversation summary: #{total_messages} messages, approximately #{total_tokens} tokens. Agents: #{inspect(agent_summaries)}"
  end

  defp summarize_agent_messages(agent_id, messages, total_tokens) do
    message_count = length(messages)

    first_content = if length(messages) > 0, do: hd(messages).content, else: ""
    last_content = if length(messages) > 0, do: List.last(messages).content, else: ""

    first_words = extract_key_words(first_content, 5)
    last_words = extract_key_words(last_content, 5)

    %{
      agent_id: agent_id,
      message_count: message_count,
      estimated_tokens: total_tokens,
      key_topics: first_words ++ last_words,
      summary:
        "Agent #{agent_id}: #{message_count} messages (~#{total_tokens} tokens). Key topics: #{Enum.join(first_words ++ last_words, ", ")}"
    }
  end

  defp extract_key_words(nil, _count), do: []
  defp extract_key_words("", _count), do: []

  defp extract_key_words(text, count) do
    text
    |> String.downcase()
    |> String.split(~r/\s|[^\w]+/)
    |> Enum.filter(fn word -> String.length(word) > 3 end)
    |> Enum.uniq()
    |> Enum.take(count)
  end

  defp matches_search?(conversation, query, opts) do
    content_match =
      String.contains?(String.downcase(conversation.content), String.downcase(query))

    agent_match =
      if opts[:agent_id], do: conversation.agent_id == opts[:agent_id], else: true

    role_match = if opts[:role], do: conversation.role == opts[:role], else: true

    content_match and agent_match and role_match
  end
end
