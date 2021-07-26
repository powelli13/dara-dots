defmodule GameServerWeb.PongGameChannel do
  use GameServerWeb, :channel
  alias GameServer.PongGame

  def join("pong_game:" <> game_id, _params, socket) do
    send(self(), :after_join)

    {:ok, assign(socket, game_id: game_id)}
  end

  def handle_in("move_paddle_left", _, socket) do
    PongGame.move_paddle_left(socket.assigns.game_id, socket.assigns.player_id)

    {:noreply, socket}
  end

  def handle_in("move_paddle_right", _, socket) do
    PongGame.move_paddle_right(socket.assigns.game_id, socket.assigns.player_id)

    {:noreply, socket}
  end

  # TODO after the game has ended find a way to gracefully handle moves, or just don't handle them
  # This causes GenServer crashes after the game ends currently
  def handle_info(:after_join, socket) do
    %{
      :top_player_id => top_player_id,
      :bot_player_id => bot_player_id
    } = PongGame.get_player_positions(socket.assigns.game_id)

    case socket.assigns.player_id do
      ^top_player_id ->
        push(
          socket,
          "player_status",
          %{position: "top"}
        )

      ^bot_player_id ->
        push(
          socket,
          "player_status",
          %{position: "bottom"}
        )
    end

    {:noreply, socket}
  end

  def handle_info({:new_game_state, game_state}, socket) do
    push(
      socket,
      "game_state",
      %{
        ballX: game_state.ball_x,
        ballY: game_state.ball_y,
        topPaddleX: game_state.top_paddle_x,
        botPaddleX: game_state.bot_paddle_x,
        topPlayerScore: game_state.top_player_score,
        botPlayerScore: game_state.bot_player_score,
        topPlayerName: game_state.top_player_name,
        botPlayerName: game_state.bot_player_name
      }
    )

    {:noreply, socket}
  end

  def handle_info({:game_over, winner_name}, socket) do
    push(
      socket,
      "game_over",
      %{
        winnerName: winner_name
      }
    )
  end
end
