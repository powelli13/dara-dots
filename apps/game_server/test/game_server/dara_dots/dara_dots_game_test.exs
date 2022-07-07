defmodule GameServer.DaraDots.DaraDotsGameTest do
  use ExUnit.Case, async: true
  alias GameServer.DaraDots.DaraDotsGame

  # setup do
  # id = "test_id"
  # {:ok, _pid} = DaraDotsGame.start(id)

  # {:ok, game_id: id}
  # end

  test "start should create new board" do
    id = "test_id"
    {:ok, _pid} = DaraDotsGame.start(id)
    board = DaraDotsGame.get_full_board(id)

    assert MapSet.size(board.dot_coords) != 0
  end

  test "submitted moves should only take affect if it is that players turn" do
    assert true
  end

  test "submit_move should populate pending action", state do
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

  test "place_runner should populate pending action", state do
    id = "test_id_3"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "player_one")
    DaraDotsGame.add_player(id, "player_two")

    DaraDotsGame.place_runner(id, "player_one", 1, 3)

    pending_actions = DaraDotsGame.get_pending_actions(id)

    actual = pending_actions |> Map.keys() |> Enum.count()

    assert actual == 1
  end
end
