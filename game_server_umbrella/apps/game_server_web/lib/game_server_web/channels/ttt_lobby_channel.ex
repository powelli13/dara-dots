defmodule GameServerWeb.TttLobbyChannel do
  @moduledoc """
  Channel used to facilitate the chatting and queueing for games
  in Tic Tac Toe lobby.
  """
  use GameServerWeb, :channel

  # TODO consider removing lobby id?
  def join("ttt_lobby:" <> lobby_id, %{"username" => username}, socket) do
    socket =
      socket
      |> assign(:username, username)
      |> assign(:lobby_id, lobby_id)

    {:ok, socket}
  end

  # Handle messages from the queue indicating that a game is ready
  def handle_info({:start_game, player_one_id, player_two_id, new_game_id}, socket) do
    if socket.assigns.player_id == player_one_id ||
         socket.assigns.player_id == player_two_id do
      push(socket, "game_started", %{username: socket.assigns.username, game_id: new_game_id})
    end

    {:noreply, socket}
  end

  def handle_in("join_queue", _, socket) do
    GameServer.TttPlayerQueue.add_player(socket.assigns.player_id, socket.assigns.username)

    {:noreply, socket}
  end

  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(socket, "new_msg", %{username: socket.assigns.username, message: message})
    {:noreply, socket}
  end
end
