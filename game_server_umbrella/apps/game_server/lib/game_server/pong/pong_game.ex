defmodule GameServer.PongGame do
  use GenServer
  alias Phoenix.PubSub

  @broadcast_frequency 35

  @paddle_right_limit 0.95
  @paddle_left_limit 0.05
  @paddle_move_step 0.05

  def move_paddle_left(game_id) do
    GenServer.cast(via_tuple(game_id), :move_paddle_left)
  end

  def move_paddle_right(game_id) do
    GenServer.cast(via_tuple(game_id), :move_paddle_right)
  end

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
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    initial_state = %{
      game_id: game_id,
      ball_x: 0.5,
      ball_y: 0.5,
      bot_paddle_x: 0.05
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast(:move_paddle_right, game_state) do
    new_paddle_x =
      if game_state.bot_paddle_x <= @paddle_right_limit do
        game_state.bot_paddle_x + @paddle_move_step
      else
        game_state.bot_paddle_x
      end

    {:noreply, %{game_state | bot_paddle_x: new_paddle_x}}
  end

  @impl GenServer
  def handle_cast(:move_paddle_left, game_state) do
    new_paddle_x =
      if game_state.bot_paddle_x >= @paddle_left_limit do
        game_state.bot_paddle_x - @paddle_move_step
      else
        game_state.bot_paddle_x
      end

    {:noreply, %{game_state | bot_paddle_x: new_paddle_x}}
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, game_state) do
    # TODO separate the ball updating logic
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    r = :rand.uniform()

    ball_position = %{ball_x: r, ball_y: r}
    # cond do
    # r > 0.67 ->
    # %{ball_x: 0.7, ball_y: 0.7}

    # r > 0.33 ->
    # %{ball_x: 0.5, ball_y: 0.5}

    # true ->
    # %{ball_x: 0.3, ball_y: 0.3}
    # end

    new_game_state = %{game_state | ball_x: ball_position.ball_x, ball_y: ball_position.ball_y}

    broadcast_game_state(new_game_state)

    {:noreply, new_game_state}
  end

  defp broadcast_game_state(game_state) do
    PubSub.broadcast(
      GameServer.PubSub,
      "pong_game:" <> game_state.game_id,
      {:new_game_state,
       %{
         ball_x: game_state.ball_x,
         ball_y: game_state.ball_y,
         bot_paddle_x: game_state.bot_paddle_x
       }}
    )
  end
end
