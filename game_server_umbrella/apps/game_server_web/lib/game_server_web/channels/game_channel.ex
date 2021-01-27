defmodule GameServerWeb.GameChannel do
  @moduledoc """
  Channel used to communicate with the players of
  a game. Receives their inputs and broadcasts
  updates about game state.
  """
  use GameServerWeb, :channel
  alias GameServer.GameSupervisor
  alias GameServer.RockPaperScissors
  alias Phoenix.PubSub

  def join("game:" <> game_id, %{"username" => username}, socket) do
    updated_socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:username, username)

    {:ok, updated_socket}
  end

  # Handlers to take care of game state updates from the
  # rock_paper_scissors server that was subscribed to on join
  def handle_info(:game_drawn, socket) do
    # IO.puts("Pushing game update to socket")
    # IO.inspect(socket)
    push(socket, "player_move", %{message: "Game drawn. Thanks for playing!"})

    {:noreply, socket}
  end

  def handle_info(:game_continue, socket) do
    # IO.puts("Pushing game update to socket")
    # IO.inspect(socket)
    push(socket, "player_move", %{message: "Game not over, all players must move."})

    {:noreply, socket}
  end

  def handle_info({:game_over, winner_name}, socket) do
    # IO.puts("Pushing game update to socket")
    # IO.inspect(socket)
    push(socket, "player_move", %{message: "Game over! #{winner_name} has won."})

    {:noreply, socket}
  end

  def handle_in("player_move", %{"move" => move_string}, socket) do
    move =
      move_string
      |> String.downcase()
      |> String.to_atom()

    game_pid = GameSupervisor.find_game(socket.assigns.game_id)

    RockPaperScissors.enter_move(
      game_pid,
      socket.assigns.username,
      move
    )

    {:noreply, socket}
  end
end
