defmodule GameServer.PongGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.PongGameState

  @broadcast_frequency 35

  def move_paddle_left(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:move_paddle_left, player_id})
  end

  def move_paddle_right(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:move_paddle_right, player_id})
  end

  def set_top_paddle_player(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:set_top_paddle, player_id})
  end

  def set_bot_paddle_player(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:set_bot_paddle, player_id})
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
      top_paddle_player_id: nil,
      bot_paddle_player_id: nil,
      game_state: %PongGameState{}
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast({:move_paddle_right, player_id}, state) do
    new_game_state =
      cond do
        player_id == state.top_paddle_player_id ->
          PongGameState.move_top_paddle(
            state.game_state,
            :right
          )

        player_id == state.bot_paddle_player_id ->
          PongGameState.move_bottom_paddle(
            state.game_state,
            :right
          )

        true ->
          state.game_state
      end

    {:noreply, %{state | game_state: new_game_state}}
  end

  @impl GenServer
  def handle_cast({:move_paddle_left, player_id}, state) do
    new_game_state =
      cond do
        player_id == state.top_paddle_player_id ->
          PongGameState.move_top_paddle(
            state.game_state,
            :left
          )

        player_id == state.bot_paddle_player_id ->
          PongGameState.move_bottom_paddle(
            state.game_state,
            :left
          )

        true ->
          state.game_state
      end

    {:noreply, %{state | game_state: new_game_state}}
  end

  @impl GenServer
  def handle_cast({:set_top_paddle, player_id}, state) do
    {:noreply, %{state | top_paddle_player_id: player_id}}
  end

  @impl GenServer
  def handle_cast({:set_bot_paddle, player_id}, state) do
    {:noreply, %{state | bot_paddle_player_id: player_id}}
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
         top_paddle_x: game_state.top_paddle_x,
         bot_paddle_x: game_state.bot_paddle_x
       }}
    )
  end
end
