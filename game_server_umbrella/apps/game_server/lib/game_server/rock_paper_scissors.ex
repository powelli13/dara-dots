defmodule GameServer.RockPaperScissors do
  @moduledoc """
  Simple rock paper scissors game process that receives
  two players inputs and records results to the score board
  after the game.
  """
  use GenServer
  alias GameServer.Scoreboard

  @defeats %{
    :rock => :scissors,
    :scissors => :paper,
    :paper => :rock
  }

  # Client methods
  # TODO add unique player ids assigned by the server
  @doc """
  Receives the move for the given player_name.
  move should be either :rock, :paper or :scissors.
  """
  def enter_move(game_pid, player_name, move) when is_atom(move) do
    # TODO error or guard clause to find illegal moves?
    GenServer.call(game_pid, {:player_move, player_name, move})
  end

  @doc """
  Attempts to add a new player to the game.
  """
  def add_player(game_pid, player_name) when is_binary(player_name) do
    GenServer.cast(game_pid, {:add_player, player_name})
  end

  # TODO left off
  # if we want to start this using the dynamic supervisor 
  # we should probably change it to add players
  # after it has been started
  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id,
      name: via_tuple(game_id)
    )
  end

  def via_tuple(game_id) do
    GameServer.ProcessRegistry.via_tuple({__MODULE__, game_id})
  end

  @impl GenServer
  def init(_) do
    # TODO make a struct for this?
    initial_state = %{
      :player_one_name => nil,
      :player_two_name => nil,
      :player_one_move => nil,
      :player_two_move => nil
    }
    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast({:add_player, player_name}, game_state) do
    new_state = cond do
      is_nil(game_state[:player_one_name]) && is_nil(game_state[:player_two_name]) ->
        Map.put(game_state, :player_one_name, player_name)
      !is_nil(game_state[:player_one_name]) && is_nil(game_state[:player_two_name]) ->
        Map.put(game_state, :player_two_name, player_name)
      # if both names nil then game is full cannot add player
      true ->
        game_state
    end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:player_move, player_name, move}, _from, game_state) do
    # TODO validate attempted player name and move
    # should probably handle that using a separate game state struct
    game_state = cond do
      game_state[:player_one_name] == player_name ->
        Map.put(game_state, :player_one_move, move)
      game_state[:player_two_name] == player_name ->
        Map.put(game_state, :player_two_move, move)
      # Not a valid player name
      true ->
        game_state
    end

    # TODO should store more info int he game state struct
    # Check for any winner
    case check_victory(game_state) do
      # TODO report win or draw
      {:winner, winner_name} ->
        Scoreboard.report_win(winner_name)
        # TODO report loss and draw
        {:stop, :normal, "#{winner_name} wins!", game_state}
      :draw ->
        {:stop, :normal, "Game drawn.", game_state}
      :not_over ->
        {:reply, "Not over, all players must move.", game_state}
    end
  end

  defp check_victory(game_state) when is_map(game_state) do
    %{
      :player_one_name => player_one,
      :player_two_name => player_two,
      :player_one_move => move_one,
      :player_two_move => move_two
    } = game_state

    cond do
      is_nil(move_one) || is_nil(move_two) ->
        :not_over
      move_one == move_two ->
        :draw
      @defeats[move_one] == move_two ->
        {:winner, player_one}
      true ->
        {:winner, player_two}
    end
  end
end