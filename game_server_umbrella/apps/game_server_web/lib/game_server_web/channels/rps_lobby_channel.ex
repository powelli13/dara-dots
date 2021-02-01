defmodule GameServerWeb.RpsLobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting in the Rock Paper Scissors game Lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.GameSupervisor
  alias GameServer.RockPaperScissors

  def join("rps_lobby:" <> lobby_id, %{"username" => username}, socket) do
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
    # TODO this can be improved, maybe these can be socket_ref s instead?
    if socket.assigns.username == player_one ||
         socket.assigns.username == player_two do
      push(socket, "game_started", %{username: socket.assigns.username, game_id: new_game_id})
    end

    {:noreply, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end

  def handle_in("join_queue", %{"player_name" => player_name}, socket) do
    # TODO user socket ref here
    # [{player_queue_pid, _}] = Registry.lookup(GameServer.Registry, GameServer.PlayerQueue)

    GameServer.PlayerQueue.add_player(player_name)

    {:noreply, socket}
  end
end
