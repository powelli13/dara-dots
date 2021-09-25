defmodule GameServer.LipSyncQueue do
  @moduledoc """
  Maintains the state of participants and their
  video URLs for Lip Sync Battle teams.
  """
  use GenServer
  alias Phoenix.PubSub

  @doc """
  Add a new team to the Lip Sync queue with the given
  name and YouTube URL.
  """
  def add_team(queue_pid, team_name, youtube_url) do
    GenServer.cast(queue_pid, {:add_team, team_name, youtube_url})
  end

  @doc """
  Retrieves the current list of registered teams in the Lip Sync queue.
  """
  def get_teams(queue_pid) do
    GenServer.call(queue_pid, :get_teams)
  end

  @doc """
  Sets the queue into performance mode. All currently registered
  teams will be placed in a list of teams to perform that can be
  advanced and consumed by calling next_performer
  """
  def start_performance(queue_pid) do
    GenServer.cast(queue_pid, :start_performance)
  end

  @doc """
  Prompts the queue to move to the next performer
  """
  def next_performer(queue_pid) do
    GenServer.cast(queue_pid, :next_performer)
  end

  def start_link(queue_id) do
    GenServer.start_link(
      __MODULE__,
      queue_id
    )
  end

  @doc """
  Initializes a new Lip Sync queue process,
  preserves the queue_id in order to later send out
  PubSub broadcasts for the correct channel topic.
  """
  @impl GenServer
  def init(queue_id) do
    # Register the LipSyncQueue upon creation in order to verify 
    # queue_ids when navigation is attempted from the web side
    Registry.register(GameServer.Registry, {__MODULE__, queue_id}, queue_id)

    {:ok,
     %{
       :id => queue_id,

       # The teams registered in the queue
       :teams => %{},

       # Keeps track of whether the queue is performing
       # and the list of performers yet to perform
       :performing => false,
       :to_perform => []
     }}
  end

  @doc """
  Adds a new Team to the Queue
  """
  @impl GenServer
  def handle_cast({:add_team, team_name, video_id}, queue_state) do
    # TODO what if someone registers with an existing team name?

    # TODO probably want a more sophisticated struct to maintain participants
    # TODO should we disallow team registration when the queue is performing?
    updated_teams = Map.put(queue_state[:teams], team_name, video_id)

    # Broadcast the new participant list to the topic
    PubSub.broadcast(
      GameServer.PubSub,
      "lobby:" <> queue_state.id,
      {:updated_participant_list, updated_teams}
    )

    {:noreply,
     queue_state
     |> Map.put(:teams, updated_teams)}
  end

  @impl GenServer
  def handle_cast(:start_performance, queue_state) do
    # Set the state up so that we are ready to perform
    updated_state =
      queue_state
      |> Map.put(:performing, true)
      |> Map.put(:to_perform, Map.keys(queue_state.teams))

      # Find and broadcast the first performer
      |> broadcast_next_performer

    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_cast(:next_performer, queue_state) do
    updated_state = broadcast_next_performer(queue_state)

    {:noreply, updated_state}
  end

  # Retrieves the next random team name from the performing
  # teams and broadcasts a message to indicate that it is
  # starting to perform, then removes the team name
  # from the list to perform.
  # Returns the updated queue_state.
  # Immediately returns if the queue is not currently
  # performing.
  defp broadcast_next_performer(queue_state) do
    case queue_state.performing do
      true ->
        team_name = Enum.random(queue_state.to_perform)
        new_to_perform = List.delete(queue_state.to_perform, team_name)
        video_id = queue_state.teams[team_name]

        PubSub.broadcast(
          GameServer.PubSub,
          "lobby:" <> queue_state.id,
          {:next_performer, team_name, video_id}
        )

        # Stop performance when we run out of performers
        # TODO broadcast here that it is done?
        new_performing = !(new_to_perform == [])

        # Broadcast that the performance has ended
        unless new_performing do
          broadcast_performance_end(queue_state.id)
        end

        queue_state
        |> Map.put(:to_perform, new_to_perform)
        |> Map.put(:performing, new_performing)

      false ->
        queue_state
    end
  end

  defp broadcast_performance_end(lobby_id) do
    PubSub.broadcast(
      GameServer.PubSub,
      "lobby:" <> lobby_id,
      :performance_end
    )
  end

  @impl GenServer
  def handle_call(:get_teams, _caller, queue_state) do
    {:reply, queue_state[:teams], queue_state}
  end
end
