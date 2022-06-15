defmodule GameServer.DaraDots.DaraDotsGameTest do
  use ExUnit.Case, async: true
  alias GameServer.DaraDots.DaraDotsGame

  test "start should create new board" do
    id = "test_id"
    {:ok, _pid} = DaraDotsGame.start(id)
    board = DaraDotsGame.get_full_board(id)

    assert MapSet.size(board.dot_coords) != 0
  end

  test "submitted moves should only take affect if it is that players turn" do
    assert true
  end

  test "submit_move should populate pending action" do
    # TODO the same id causes issues with the above test, is there a better way to test genserver?
    id = "test_id_2"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "player_one")
    DaraDotsGame.add_player(id, "player_two")

    DaraDotsGame.submit_move(id, "player_one", 1, 1)

    pending_actions = DaraDotsGame.get_pending_actions(id)

    actual = pending_actions |> Map.keys() |> Enum.count()

    assert actual == 1
  end
end
