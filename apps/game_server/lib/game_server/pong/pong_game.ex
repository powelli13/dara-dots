defmodule GameServer.PongGame do
  use GenServer
  alias Phoenix.PubSub
  alias GameServer.PongGameState

  @broadcast_frequency 35
  @ball_restart_time 3000
  @score_to_win 11

  def move_paddle_left(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:move_paddle_left, player_id})
  end

  def move_paddle_right(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:move_paddle_right, player_id})
  end

  def set_top_paddle_player(game_id, player_id, player_name) do
    GenServer.cast(via_tuple(game_id), {:set_top_paddle, player_id, player_name})
  end

  def set_bot_paddle_player(game_id, player_id, player_name) do
    GenServer.cast(via_tuple(game_id), {:set_bot_paddle, player_id, player_name})
  end

  def remove_player(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:remove_player, player_id})
  end

  def get_player_positions(game_id) do
    GenServer.call(via_tuple(game_id), :get_player_positions)
  end

  def get_player_names(game_id) do
    GenServer.call(via_tuple(game_id), :get_player_names)
  end

  def start(id) do
    GenServer.start(__MODULE__, id, name: via_tuple(id))
  end

  # Use this to transform the id given to exported functions
  # before calling GenServer call or cast
  defp via_tuple(id) do
    {:via, Registry, {GameServer.Registry, {__MODULE__, id}}}
  end

  @impl GenServer
  def init(game_id) do
    # Add the game to the active list
    GameServer.PongActiveGames.add_active_game(game_id)

    # Start the state broadcasting
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    # Start the ball moving after the designated time
    Process.send_after(self(), :start_ball_moving, @ball_restart_time)

    initial_state = %{
      game_id: game_id,
      top_paddle_player_id: nil,
      bot_paddle_player_id: nil,
      top_paddle_player_name: nil,
      bot_paddle_player_name: nil,
      game_running: true,
      game_state: PongGameState.reset_ball_position_and_speed(%PongGameState{})
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
  def handle_cast({:set_top_paddle, player_id, player_name}, state) do
    {
      :noreply,
      %{state | top_paddle_player_id: player_id, top_paddle_player_name: player_name}
    }
  end

  @impl GenServer
  def handle_cast({:set_bot_paddle, player_id, player_name}, state) do
    {
      :noreply,
      %{state | bot_paddle_player_id: player_id, bot_paddle_player_name: player_name}
    }
  end

  @impl GenServer
  def handle_cast({:remove_player, player_id}, state) do
    # TODO make this count down and pause to allow for the player to rejoin
    # The player that didn't leave is the winner
    {top_player, bot_player} = {state.top_paddle_player_id, state.bot_paddle_player_id}

    case player_id do
      ^top_player ->
        broadcast_game_winner(state, state.bot_paddle_player_name)
        {:stop, :normal, state}

      ^bot_player ->
        broadcast_game_winner(state, state.top_paddle_player_name)
        {:stop, :normal, state}

      # This represents a spectator leaving, so do nothing
      _ ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call(:get_player_positions, _, state) do
    {
      :reply,
      %{
        top_player_id: state.top_paddle_player_id,
        bot_player_id: state.bot_paddle_player_id
      },
      state
    }
  end

  @impl GenServer
  def handle_call(:get_player_names, _, state) do
    {
      :reply,
      {
        state.top_paddle_player_name,
        state.bot_paddle_player_name
      },
      state
    }
  end

  @impl GenServer
  def handle_info(:broadcast_game_state, state) do
    Process.send_after(self(), :broadcast_game_state, @broadcast_frequency)

    # TODO improve this, read up on struct GenServer interaction
    # Send a message to self to restart the ball moving after 3 seconds
    {game_state, reset} = PongGameState.move_ball(state.game_state)

    if reset do
      Process.send_after(self(), :start_ball_moving, @ball_restart_time)
    end

    new_state = %{state | game_state: game_state}

    broadcast_game_state(new_state)

    # If there is a winner then broadcast it and kill the game's process
    {game_over, winner_name} = has_winner?(new_state)

    if game_over do
      broadcast_game_winner(new_state, winner_name)

      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  @impl GenServer
  def handle_info(:start_ball_moving, state) do
    {:noreply, %{state | game_state: PongGameState.start_ball_moving(state.game_state)}}
  end

  defp has_winner?(state) do
    cond do
      state.game_state.top_player_score >= @score_to_win ->
        {true, state.top_paddle_player_name}

      state.game_state.bot_player_score >= @score_to_win ->
        {true, state.bot_paddle_player_name}

      true ->
        {false, nil}
    end
  end

  defp broadcast_game_winner(state, winner_name) do
    GameServer.PongActiveGames.remove_game(state.game_id)

    PubSub.broadcast(
      GameServer.PubSub,
      "pong_game:" <> state.game_id,
      {:game_over, winner_name}
    )
  end

  defp broadcast_game_state(state) do
    PubSub.broadcast(
      GameServer.PubSub,
      "pong_game:" <> state.game_id,
      {:new_game_state,
       %{
         ball_x: state.game_state.ball_x,
         ball_y: state.game_state.ball_y,
         top_paddle_x: state.game_state.top_paddle_x,
         bot_paddle_x: state.game_state.bot_paddle_x,
         top_player_name: state.top_paddle_player_name,
         bot_player_name: state.bot_paddle_player_name,
         top_player_score: state.game_state.top_player_score,
         bot_player_score: state.game_state.bot_player_score
       }}
    )
  end
end
