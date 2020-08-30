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
  def enter_move(game_id, player_name, move) when is_atom(move) do
    # TODO error or guard clause to find illegal moves?
    GenServer.call(game_id, {:player_move, player_name, move})
  end

  def start_link(game_id, init_arg) do
    GenServer.start_link(
      __MODULE__,
      init_arg,
      name: via_tuple(game_id)
    )
  end

  def via_tuple(game_id) do
    GameServer.ProcessRegistry.via_tuple({__MODULE__, game_id})
  end

  @impl true
  def init([player_one: player_one, player_two: player_two]) do
    # data structure to record player names and move inputs
    # when both players move calculate win/loss/draw and
    # send to scoreboard
    # TODO pull player names from opts for state initialization
    {:ok, %{player_one => nil, player_two => nil}}
  end

  @impl true
  def handle_call({:player_move, player_name, move}, _from, game_state) do
    # TODO validate attempted player name and move
    # should probably handle that using a separate game state struct
    game_state = Map.put(game_state, player_name, move)

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
    [player_one, player_two] = Map.keys(game_state)
    %{
      ^player_one => move_one,
      ^player_two => move_two
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