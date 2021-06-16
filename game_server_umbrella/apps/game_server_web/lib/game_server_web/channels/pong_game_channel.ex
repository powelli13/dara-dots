defmodule GameServerWeb.PongGameChannel do
  use GameServerWeb, :channel
  alias GameServer.PongGame

  def join("pong_game:" <> game_id, _params, socket) do
    # Start the pong game
    # TODO for testing only, move this to Pong Queue later
    GameServer.PongGameSupervisor.find_game(game_id)
    
    IO.inspect "player ID in pong game channel"
    IO.inspect socket.assigns.player_id

    {:ok, assign(socket, game_id: game_id)}
  end

  def handle_in("move_paddle_left", _, socket) do
    IO.inspect "attempting to move left"
    PongGame.move_paddle_left(socket.assigns.game_id, socket.assigns.player_id)

    {:noreply, socket}
  end

  def handle_in("move_paddle_right", _, socket) do
    IO.inspect "attempting to move right"
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
        botPaddleX: game_state.bot_paddle_x
      }
    )

    {:noreply, socket}
  end
end
