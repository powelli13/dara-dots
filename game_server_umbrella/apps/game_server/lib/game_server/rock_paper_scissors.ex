defmodule GameServer.RockPaperScissors do
  @moduledoc """
  Simple rock paper scissors game process that receives
  two players inputs and records results to the score board
  after the game.
  """
  use GenServer
  alias GameServer.Scoreboard
  alias Phoenix.PubSub

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
    GenServer.cast(game_pid, {:player_move, player_name, move})
  end

  @doc """
  Attempts to add a new player to the game.
  """
  def add_player(game_pid, player_name) when is_binary(player_name) do
    GenServer.cast(game_pid, {:add_player, player_name})
  end

  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id
    )
  end

  @impl GenServer
  def init(game_id) do
    # IO.inspect Registry.register(GameServer.Registry, {__MODULE__, game_id}, game_id)
    # TODO make a struct for this?
    initial_state = %{
      :game_id => game_id,
      :player_one_name => nil,
      :player_two_name => nil,
      :player_one_move => nil,
      :player_two_move => nil
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_cast({:add_player, player_name}, game_state) do
    new_state =
      cond do
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
  def handle_cast({:player_move, player_name, move}, game_state) do
    IO.puts("Player #{player_name} entered move of #{move}")
    # TODO this does not correctly update, this entire module is pretty gross
    # should be refactored with tests addeD
    # should probably handle that using a separate game state struct
    game_state =
      cond do
        game_state[:player_one_name] == player_name ->
          IO.puts("player one moved")
          Map.put(game_state, :player_one_move, move)

        game_state[:player_two_name] == player_name ->
          IO.puts("player two moved")
          Map.put(game_state, :player_two_move, move)

        # Not a valid player name
        true ->
          IO.puts("no game change")
          game_state
      end

    # TODO should store more info int he game state struct
    # Check for any winner
    case check_victory(game_state) do
      # TODO report win or draw
      {:winner, winner_name} ->
        # Scoreboard.report_win(winner_name)
        broadcast_game_update(game_state[:game_id], {:game_over, winner_name})
        # TODO report loss and draw
        {:stop, :normal, game_state}

      :draw ->
        broadcast_game_update(game_state[:game_id], :game_drawn)
        {:stop, :normal, game_state}

      :not_over ->
        broadcast_game_update(game_state[:game_id], :game_continue)
        {:noreply, game_state}
    end
  end

  defp check_victory(game_state) when is_map(game_state) do
    IO.puts("game state in check victory")
    IO.puts(game_state[:player_one_move])
    IO.puts(game_state[:player_two_move])

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

  defp broadcast_game_update(game_id, update_term) do
    IO.puts("RPC broadcasting! Sending game update")
    IO.puts(update_term)
    PubSub.broadcast(GameServer.PubSub, "game:" <> game_id, update_term)
  end
end
