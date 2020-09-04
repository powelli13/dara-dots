defmodule GameServerWeb.GameChannel do
  @moduledoc """
  Channel used to communicate with the players of
  a game. Receives their inputs and broadcasts
  updates about game state.
  """
  use GameServerWeb, :channel
  alias GameServer.GameSupervisor
  alias GameServer.RockPaperScissors

  def join("game:" <> game_id, %{"username" => username}, socket) do
    updated_socket = socket
      |> assign(:game_id, game_id)
      |> assign(:username, username)

    {:ok, updated_socket}
  end

  def handle_in("player_move", %{"move" => move_string}, socket) do
    # TODO move this to appropriate module
    move = move_string
      |> String.downcase
      |> String.to_atom

    game_pid = GameSupervisor.find_game(socket.assigns.game_id)

    game_state = RockPaperScissors.enter_move(
      game_pid,
      socket.assigns.username,
      move
    )

    broadcast!(
      socket,
      "player_move",
      %{message: "Player #{socket.assigns.username} has played #{move}!"})
    broadcast!(
      socket,
      "player_move",
      %{message: game_state}
    )
  end
end