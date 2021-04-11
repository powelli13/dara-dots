defmodule GameServerWeb.TttGameChannel do
  use GameServerWeb, :channel
  alias GameServer.TicTacToe

  def join("ttt_game:" <> game_id, %{"username" => username}, socket) do
    # TODO replace user name with player id at socket join
    updated_socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:username, username)

    {:ok, updated_socket}
  end

  def handle_in("submit_move", %{"move_index" => move_index}, socket) do
    [{game_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.TicTacToe, socket.assigns.game_id}
      )

    TicTacToe.make_move(
      game_pid,
      socket.assigns.username,
      move_index
    )

    {:noreply, socket}
  end

  def handle_info({:new_board_state, board_state}, socket) do
    push(socket, "new_board_state", %{board: board_state})
    {:noreply, socket}
  end

  def handle_info({:game_winner, winner_piece, winner_name, indices}, socket) do
    push(
      socket,
      "game_winner",
      %{piece: winner_piece, name: winner_name, indices: indices}
    )

    {:noreply, socket}
  end

  def handle_info(:game_drawn, socket) do
    push(
      socket,
      "game_drawn",
      %{}
    )

    {:noreply, socket}
  end
end
