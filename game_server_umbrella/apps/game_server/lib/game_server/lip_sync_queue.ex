defmodule GameServer.LipSyncQueue do
  @moduledoc """
  Maintains the state of participants and their
  video URLs for Lip Sync Battle teams.
  """
  use GenServer
  alias Phoenix.PubSub

  @doc """
  Add a new participant to the Lip Sync queue with the given
  player name and YouTube URL.
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

  def start_link(queue_id) do
    GenServer.start_link(
      __MODULE__,
      queue_id,
      name: __MODULE__
    )
  end

  # def via_tuple(queue_id) do
  #  GameServer.ProcessRegistry.via_tuple({__MODULE__, queue_id})
  # end

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
       :teams => %{}
     }}
  end

  @impl GenServer
  def handle_cast({:add_team, team_name, youtube_url}, queue_state) do
    # Retrieve the youtube video ID from the submitted URL
    # TODO error case here? maybe this should move to the web side
    video_id =
      ~r{^.*(?:youtu\.be/|\w+/|v=)(?<id>[^#&?]*)}
      |> Regex.named_captures(youtube_url)

    # TODO probably want a more sophisticated struct to maintain participants
    updated_teams = Map.put(queue_state[:teams], team_name, video_id)

    # Broadcast the new participant list to the topic
    PubSub.broadcast(
      GameServer.PubSub,
      "lobby:" <> queue_state[:id],
      {:updated_participant_list, updated_teams}
    )

    {:noreply,
     queue_state
     |> Map.put(:teams, updated_teams)}
  end

  @impl GenServer
  def handle_call(:get_teams, _caller, queue_state) do
    {:reply, queue_state[:teams], queue_state}
  end
end
