defmodule GameServer.TicTacToe do
  use GenServer

  def get_board_state(game_pid) do
    GenServer.call(game_pid, :get_board_state)
  end

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

    # Board is laid out how it looks
    initial_state = %{
      :game_id => game_id,
      :board_state => %{
        0 => " ",
        1 => " ",
        2 => " ",
        3 => " ",
        4 => " ",
        5 => " ",
        6 => " ",
        7 => " ",
        8 => " "
      }
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(:get_board_state, _, game_state) do
    board_as_list =
      game_state[:board_state]
      |> Enum.map(fn {_, sq} -> sq end)

    {:reply, board_as_list, game_state}
  end
end
