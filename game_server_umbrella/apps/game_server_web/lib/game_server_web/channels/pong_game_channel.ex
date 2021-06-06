defmodule GameServerWeb.PongGameChannel do
  use GameServerWeb, :channel

  def join("pong_game:" <> game_id, _params, socket) do
    # Process.send_after(self(), :move_ball, 1000)
    # Start the pong game
    # TODO for testing only, move this to Pong Queue later
    GameServer.PongGameSupervisor.find_game(game_id)

    {:ok, assign(socket, game_id: game_id)}
  end

  def handle_info({:move_ball, %{ball_x: ball_x, ball_y: ball_y}}, socket) do
    push(socket, "move_ball", %{ballX: ball_x, ballY: ball_y})

    {:noreply, socket}
  end
end
