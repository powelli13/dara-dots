defmodule GameServerWeb.PongGameChannel do
  use GameServerWeb, :channel

  def join("pong_game:" <> game_id, _params, socket) do
    Process.send_after(self(), :move_ball, 1000)

    {:ok, socket}
  end

  def handle_info(:move_ball, socket) do
    Process.send_after(self(), :move_ball, 1000)

    r = :rand.uniform()

    ball_position =
      cond do
        r > 0.67 ->
          %{ballX: 350, ballY: 350}

        r > 0.33 ->
          %{ballX: 250, ballY: 250}

        true ->
          %{ballX: 150, ballY: 150}
      end

    push(socket, "move_ball", ball_position)

    {:noreply, socket}
  end
end