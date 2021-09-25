defmodule GameServerWeb.TttGameChannel do
  use GameServerWeb, :channel
  alias GameServer.TicTacToe

  def join("ttt_game:" <> game_id, %{"username" => username}, socket) do
    updated_socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:username, username)

    send(self(), :after_join)

    {:ok, updated_socket}
  end

  def handle_in("submit_move", %{"move_index" => move_index}, socket) do
    game_pid = get_game_pid(socket.assigns.game_id)

    TicTacToe.make_move(
      game_pid,
      socket.assigns.player_id,
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

  def handle_info(:after_join, socket) do
    game_pid = get_game_pid(socket.assigns.game_id)

    %{
      :cross_player_name => cross_player,
      :circle_player_name => circle_player
    } = TicTacToe.get_player_names(game_pid)

    case socket.assigns.username do
      ^circle_player ->
        push(
          socket,
          "game_status",
          %{opponent: cross_player, piece: "O"}
        )

      ^cross_player ->
        push(
          socket,
          "game_status",
          %{opponent: circle_player, piece: "X"}
        )
    end

    {:noreply, socket}
  end

  defp get_game_pid(game_id) do
    [{game_pid, _}] =
      Registry.lookup(
        GameServer.Registry,
        {GameServer.TicTacToe, game_id}
      )

    game_pid
  end
end
