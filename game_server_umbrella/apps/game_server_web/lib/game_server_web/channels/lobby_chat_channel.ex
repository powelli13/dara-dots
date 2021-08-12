defmodule GameServerWeb.LobbyChatChannel do
  @moduledoc """
  Generic Lobby Chat Channel used to handle the
  chat and queue functionality for the various lobbies.
  """
  use GameServerWeb, :channel

  def join("lobby_chat:" <> lobby_name, %{"username" => username}, socket) do
    socket =
      socket
      |> assign(:username, username)
      |> assign(:lobby_name, lobby_name)

    {:ok, socket}
  end

  # Handles commands to join game queues from the client
  def handle_in("join_queue", _, socket) do
    case socket.assigns.lobby_name do
      "pong" ->
        GameServer.PongPlayerQueue.add_player(
          socket.assigns.player_id,
          socket.assigns.username
        )
    end

    {:noreply, socket}
  end

  # Handles commands to leave the queue from the client
  def handle_in("leave_queue", _, socket) do
    case socket.assigns.lobby_name do
      "pong" ->
        GameServer.PongPlayerQueue.remove_player(socket.assigns.player_id)
    end

    {:noreply, socket}
  end

  # Handles chat messages from the client
  def handle_in("new_msg", %{"message" => message}, socket) do
    broadcast!(
      socket,
      "new_msg",
      %{
        username: socket.assigns.username,
        message: message
      }
    )

    {:noreply, socket}
  end

  # should set which queue module to join based on lobby_name
  def handle_info({:start_game, first_player_id, second_player_id, new_game_id}, socket) do
    if socket.assigns.player_id == first_player_id ||
         socket.assigns.player_id == second_player_id do
      push(
        socket,
        "game_started",
        %{
          game_url: "#{get_game_route(socket)}?id=#{new_game_id}"
        }
      )
    end

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    # The Channel terminating means that the user must have left the lobby
    # so remove them from the queue
    case socket.assigns.lobby_name do
      "pong" ->
        GameServer.PongPlayerQueue.remove_player(socket.assigns.player_id)
    end

    reason
  end

  defp get_game_route(socket) do
    case socket.assigns.lobby_name do
      "pong" ->
        "pong-game"
    end
  end
end
