defmodule GameServer.GameSupervisor do
  @moduledoc """
  Dynamic supervisor used to retrieve the PIDs
  of running games given the ID generated when
  the game process was started.
  """
  alias GameServer.ProcessRegistry
  
  def start_link do
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def find_game(game_id) do
    # TODO this may not be exactly what we want because
    # a non-started game needs to start with players
    # maybe registry is better?
    case start_child(game_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(game_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GameServer.RockPaperScissors, game_id}
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end