defmodule GameServer.TicTacToe do
  use GenServer

  @impl GenServer
  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id
    )
  end

  @impl GenServer
  def init(game_id) do
    # TODO needed for when channels start looking us up
    # Registry.register(GameServer.Registry, {__MODULE__, game_id}, game_id)

    initial_state = %{
      :game_id => game_id
      # TODO use a Map for the board state is best I think
    }

    {:ok, initial_state}
  end
end
