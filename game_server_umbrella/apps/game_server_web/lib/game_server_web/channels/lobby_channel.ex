defmodule GameServerWeb.LobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.GameSupervisor
  alias GameServer.LipSyncQueue
  alias GameServer.RockPaperScissors

  @system_admin_name "Administrator Alligator"

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

    # Send the currently registered teams to the lobby
    # entrant when they join.
    # TODO when this fails or they navigate to the page without a valid
    # lobby ID the channel process will continue to die and try to rejoin,
    # should navigate them away or something
    [{queue_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.LipSyncQueue, socket.assigns[:lobby_id]}
      )

    push(socket, "participant_list", %{updated_list: LipSyncQueue.get_teams(queue_pid)})

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

  # Handle an update to which team is performing
  def handle_info({:next_performer, team_name, video_id}, socket) do
    push(socket, "new_msg", %{
      username: @system_admin_name,
      message: "Next up is team #{team_name}, enjoy!"
    })

    # TODO add performing team name to this
    # also I think this should be a push
    push(socket, "update_video", %{new_id: video_id, team_name: team_name})

    {:noreply, socket}
  end

  # Handle message indicating that the performance ended
  def handle_info(:performance_end, socket) do
    push(socket, "new_msg", %{
      username: @system_admin_name,
      message: "The performances have ended, thanks for participating!"
    })

    push(socket, "performance_end", %{continue: false})

    {:noreply, socket}
  end

  # Handle message from the client to start the performance
  def handle_in("start_performance", _, socket) do
    [{queue_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.LipSyncQueue, socket.assigns[:lobby_id]}
      )

    LipSyncQueue.start_performance(queue_pid)

    {:noreply, socket}
  end

  # Handle message from the client to advance 
  # the queue to the next performer
  def handle_in("next_performer", _, socket) do
    [{queue_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.LipSyncQueue, socket.assigns[:lobby_id]}
      )

    LipSyncQueue.next_performer(queue_pid)

    {:noreply, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end

  # Handles teams registering for the lip sync queue
  def handle_in("register_team", %{"team_name" => team_name, "video_url" => video_url}, socket) do
    # Find the Lip Sync queue for this lobby
    # This will fail if there is no queue for this lobby
    [{queue_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.LipSyncQueue, socket.assigns[:lobby_id]}
      )

    LipSyncQueue.add_team(
      queue_pid,
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
