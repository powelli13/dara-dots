defmodule GameServerWeb.GameChannel do
  @moduledoc """
  Channel used to communicate with the players of
  a game. Receives their inputs and broadcasts
  updates about game state.
  """
  use GameServerWeb, :channel

  def join("game:" <> game_id, %{"username" => username}, socket) do
    updated_socket = socket
      |> assign(:game_id, game_id)
      |> assign(:username, username)

    {:ok, updated_socket}
  end

  def handle_in("player_move", _payload, socket) do
    broadcast!(
      socket,
      "player_move",
      %{message: "Player #{socket.assigns.username} has moved!"})
  end
end