defmodule GameServer.TttGameSupervisor do
  @moduledoc """
  Dynamic supervisor used to retrieve the PIDs
  of Tic Tac Toe running games given the ID
  generated when the game process was started.
  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Used to retrieve the process for an existing
  Tic Tac Toe game based on the ID or start 
  a new game.
  """
  def find_game(game_id) do
    case start_child(game_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def start_child(game_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GameServer.TicTacToe, game_id}
    )
  end
end
