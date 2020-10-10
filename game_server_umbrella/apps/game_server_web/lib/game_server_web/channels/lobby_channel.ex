defmodule GameServerWeb.LobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.LipSyncQueue
  alias GameServer.GameSupervisor
  alias GameServer.LipSyncQueueSupervisor
  alias GameServer.LipSyncQueue
  alias GameServer.RockPaperScissors

  def join("lobby:" <> lobby_id, %{"username" => username}, socket) do
    send(self(), :after_join)

    socket =
      socket
      |> assign(:username, username)
      |> assign(:lobby_id, lobby_id)

    {:ok, socket}
  end

  # Used to setup channel presence after a user joins.
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.username, %{})

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  # Handle messages from the queue indicating that a game is ready
  def handle_info({:start_game, player_one, player_two, new_game_id}, socket) do
    # Start the game and add players
    start_game_pid = GameSupervisor.find_game(new_game_id)

    # TODO this can be improved, maybe these can be socket_ref s instead?
    if socket.assigns.username == player_one ||
         socket.assigns.username == player_two do
      RockPaperScissors.add_player(start_game_pid, socket.assigns.username)
      push(socket, "game_started", %{username: socket.assigns.username, game_id: new_game_id})
    end

    {:noreply, socket}
  end

  # Handle updated Lip Sync queue state showing new participants
  def handle_info({:updated_participant_list, updated_list}, socket) do
    broadcast!(socket, "participant_list", %{updated_list: updated_list})

    {:noreply, socket}
  end

  # Invoked when the queue sends that people are ready to play
  # def handle_in("join_queue", _, socket) do
  #  PlayerQueue.add_player(socket.assigns.username)
  #
  #    {:noreply, socket}
  #  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end

  # Handles teams registering for the lip sync queue
  def handle_in("register_team", %{"team_name" => team_name, "video_url" => video_url}, socket) do
    # Find the Lip Sync queue for this lobby
    # case Registry.lookup(
    #       GameServer.Registry,
    #       {LipSyncQueue, socket.assigns[:lobby_id]}
    #     ) do
    #  [{pid, queue_id}] ->
    #    LipSyncQueue.add_team(pid, team_name, video_url)
    #
    #      [] ->
    #        # TODO problem here since the queue isn't running, start a new one?
    #        nil
    #    end

    # lip_sync_queue_pid = ProcessRegistry.where_is(socket.assigns[:lobby_id])

    # TODO parse the video ID here, return errors as needed
    # and send just the ID
    # LipSyncQueue.add_team(lip_sync_queue_pid, team_name, video_url)

    LipSyncQueue.add_team(
      LipSyncQueueSupervisor.find_queue(socket.assigns[:lobby_id]),
      team_name,
      video_url
    )

    {:noreply, socket}
  end

  # Handle event that updates the video id that should play
  def handle_in("update_video", %{"new_id" => new_id}, socket) do
    broadcast!(socket, "update_video", %{new_id: new_id})
    {:noreply, socket}
  end
end
