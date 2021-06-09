defmodule GameServer.PongGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.PongGameState

  @broadcast_frequency 35

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
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    initial_state = %{
      game_id: game_id,
      game_state: %PongGameState{}
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast(:move_paddle_right, state) do
    new_game_state =
      PongGameState.move_bottom_paddle(
        state.game_state,
        :right
      )

    {:noreply, %{state | game_state: new_game_state}}
  end

  @impl GenServer
  def handle_cast(:move_paddle_left, state) do
    new_game_state =
      PongGameState.move_bottom_paddle(
        state.game_state,
        :left
      )

    {:noreply, %{state | game_state: new_game_state}}
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, state) do
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    new_game_state = PongGameState.move_ball(state.game_state)

    broadcast_game_state(new_game_state, state.game_id)

    {:noreply, %{state | game_state: new_game_state}}
  end

  defp broadcast_game_state(game_state, game_id) do
    PubSub.broadcast(
      GameServer.PubSub,
      "pong_game:" <> game_id,
      {:new_game_state,
       %{
         ball_x: game_state.ball_x,
         ball_y: game_state.ball_y,
         bot_paddle_x: game_state.bot_paddle_x
       }}
    )
  end
end
