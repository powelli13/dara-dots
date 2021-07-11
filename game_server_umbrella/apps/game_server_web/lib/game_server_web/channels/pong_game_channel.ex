defmodule GameServerWeb.PongGameChannel do
  use GameServerWeb, :channel
  alias GameServer.PongGame

  def join("pong_game:" <> game_id, _params, socket) do
    # Start the pong game
    # TODO for testing only, move this to Pong Queue later
    GameServer.PongGameSupervisor.find_game(game_id)

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
        botPlayerScore: game_state.bot_player_score
      }
    )

    {:noreply, socket}
  end
end
