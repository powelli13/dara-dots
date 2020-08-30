defmodule GameServer.RockPaperScissors do
  @moduledoc """
  Simple rock paper scissors game process that receives
  two players inputs and records results to the score board
  after the game.
  """
  use GenServer

  # Client methods
  # TODO add unique player ids assigned by the server
  @doc """
  Receives the move for the given player_name.
  move should be either :rock, :paper or :scissors.
  """
  def enter_move(game_name, player_name, move) when is_atom(move) do
    # TODO error or guard clause to find illegal moves?
    GenServer.call(game_name, {:player_move, player_name, move})
  end

  def start_link(name) do
    GenServer.start_link(
      __MODULE__,
      name,
      name: via_tuple(name))# TODO via_tuple here
  end

  def via_tuple(name) do
    GameServer.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  @impl true
  def init(opts) do
    # data structure to record player names and move inputs
    # when both players move calculate win/loss/draw and
    # send to scoreboard
    # TODO pull player names from opts for state initialization
    {:ok, %{}}
  end

  @impl true
  def handle_call({:player_move, player_name, move}, _from, move_state) do
    # TODO implement
    {:reply, "#{player_name} gave a move of #{move}", move_state}
  end
end