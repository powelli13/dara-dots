defmodule GameServer.TicTacToeTest do
  use ExUnit.Case, async: true

  alias GameServer.TicTacToe

  setup do
    game_id = "test_ttt_id"
    {:ok, pid} = GenServer.start_link(GameServer.TicTacToe, game_id)

    {:ok, ttt_game_pid: pid, game_id: game_id}
  end

  test "initial board is empty", state do
    init_board = TicTacToe.get_board_state(state[:ttt_game_pid])

    assert length(init_board) == 9, "incorrect board length"

    Enum.map(init_board, fn sq ->
      assert sq == " "
    end)
  end
end
