defmodule GameServer.DaraDots.DaraDotsGameTest do
  use ExUnit.Case, async: true
  alias GameServer.DaraDots.DaraDotsGame

  # setup do
  # game_id = "dara_dots_id"
  # {:ok, pid} = GenServer.start_link(GameServer.DaraDots.DaraDotsGame, game_id)

  # {:ok, game_pid: pid, game_id: game_id}
  # end

  test "start should create new board" do
    id = "test_id"
    {:ok, _pid} = DaraDotsGame.start(id)
    board = DaraDotsGame.get_full_board(id)

    assert MapSet.size(board.dot_coords) != 0
  end
end
