defmodule GameServer.PongGame do
  use GenServer
  alias Phoenix.PubSub

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  # Use this to transform the id given to exported functions
  # before calling GenServer call or cast
  defp via_tuple(id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, id}}}
  end

  @impl GenServer
  def init(game_id) do
    # TODO schedule game state broadcasting
    Process.send_after(self(), :broadcast_game_state, 500)

    initial_state = %{
      game_id: game_id,
      ball_x: 250,
      ball_y: 250
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, game_state) do
    # TODO separate the ball updating logic
    Process.send_after(self(), :broadcast_game_state, 500)

    r = :rand.uniform()

    ball_position =
      cond do
        r > 0.67 ->
          %{ball_x: 350, ball_y: 350}

        r > 0.33 ->
          %{ball_x: 250, ball_y: 250}

        true ->
          %{ball_x: 150, ball_y: 150}
      end

    new_game_state = %{game_state | ball_x: ball_position.ball_x, ball_y: ball_position.ball_y}

    broadcast_game_state(new_game_state)

    {:noreply, new_game_state}
  end

  defp broadcast_game_state(game_state) do
    PubSub.broadcast(
      GameServer.PubSub,
      "pong_game:" <> game_state.game_id,
      {:move_ball, %{ball_x: game_state.ball_x, ball_y: game_state.ball_y}}
    )
  end
end
