defmodule GameServerWeb.TttLobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting and queueing for games
  in Tic Tac Toe lobby.
  """
  use GameServerWeb, :channel
  alias GameServerWeb.Presence
  alias GameServer.TicTacToe

  # TODO consider removing lobby id?
  def join("ttt_lobby:" <> lobby_id, %{"username" => username}, socket) do
    socket =
      socket
      |> assign(:username, username)
      |> assign(:lobby_id, lobby_id)

    {:ok, socket}
  end

  # Handle messages from the queue indicating that a game is ready
  def handle_info({:start_game, player_one, player_two, new_game_id}, socket) do
    # TODO this can be improved, maybe these can be socket_ref s instead?
    # Let's use GUIDs assigned when the socket connects
    if socket.assigns.username == player_one ||
         socket.assigns.username == player_two do
      push(socket, "game_started", %{username: socket.assigns.username, game_id: new_game_id})
    end

    {:noreply, socket}
  end

  def handle_in("join_queue", %{"player_name" => player_name}, socket) do
    GameServer.TttPlayerQueue.add_player(player_name)

    {:noreply, socket}
  end
end
