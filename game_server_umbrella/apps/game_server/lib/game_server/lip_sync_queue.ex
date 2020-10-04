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
  def add_participant(queue_pid, player_name, youtube_url) do
    GenServer.cast(queue_pid, {:add_participant, player_name, youtube_url})
  end

  def start_link(queue_id) do
    GenServer.start_link(
      __MODULE__,
      queue_id,
      name: via_tuple(queue_id)
    )
  end

  def via_tuple(queue_id) do
    GameServer.ProcessRegistry.via_tuple({__MODULE__, queue_id})
  end

  @doc """
  Initializes a new Lip Sync queue process,
  preserves the queue_id in order to later send out
  PubSub broadcasts for the correct channel topic.
  """
  @impl GenServer
  def init(queue_id) do
    {:ok,
     %{
       :id => queue_id,
       :participants => []
     }}
  end

  @impl GenServer
  def handle_cast({:add_participant, player_name, youtube_url}, queue_state) do
    # Retrieve the youtube video ID from the submitted URL
    # TODO error case here? maybe this should move to the web side
    video_id =
      ~r{^.*(?:youtu\.be/|\w+/|v=)(?<id>[^#&?]*)}
      |> Regex.named_captures(youtube_url)

    # TODO probably want a more sophisticated struct to maintain participants
    updated_participants = [{player_name, video_id} | queue_state[:participants]]

    # Broadcast the new participant list to the topic
    PubSub.broadcast(
      GameServer.PubSub,
      "lobby:" <> queue_state[:id],
      {:updated_participant_list, updated_participants}
    )

    {:noreply,
     queue_state
     |> Map.put(:participants, updated_participants)}
  end
end
