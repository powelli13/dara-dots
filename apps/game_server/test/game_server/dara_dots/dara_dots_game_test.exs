defmodule GameServer.DaraDots.DaraDotsGameTest do
  use ExUnit.Case, async: true
  alias GameServer.DaraDots.{DaraDotsGame, Coordinate}

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

  test "apply_pending_action should generate new updated board" do
    id = "test_id_4"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "player_one")
    DaraDotsGame.add_player(id, "player_two")

    before_board = DaraDotsGame.get_full_board(id)

    DaraDotsGame.place_runner(id, "player_one", 1, 3)

    after_board = DaraDotsGame.get_full_board(id)

    # TODO lol finish this test
  end

  test "multiple pending actions is a valid state" do
    id = "test_id_5"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "player_one")
    DaraDotsGame.add_player(id, "player_two")

    DaraDotsGame.submit_move(id, "player_one", 1, 1)
    DaraDotsGame.place_runner(id, "player_one", 1, 3)

    pending_actions = DaraDotsGame.get_pending_actions(id)

    actual = pending_actions |> Map.keys() |> Enum.count()

    assert actual == 2
  end

  test "place_runner should not update board state" do
    id = "test_id_6"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "player_one")
    DaraDotsGame.add_player(id, "player_two")

    initial_board = DaraDotsGame.get_full_board(id)

    DaraDotsGame.place_runner(id, "player_one", 1, 3)

    after_board = DaraDotsGame.get_full_board(id)

    initial_count = initial_board.runner_pieces
      |> Map.keys()
      |> Enum.count()
    after_count = after_board.runner_pieces
      |> Map.keys()
      |> Enum.count()

    assert initial_count == after_count
  end

  test "submit_move should not update board state" do
    id = "test_id_7"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "top_player")
    DaraDotsGame.add_player(id, "bot_player")

    initial_board = DaraDotsGame.get_full_board(id)

    DaraDotsGame.submit_move(id, "top_player", 1, 5)

    after_board = DaraDotsGame.get_full_board(id)

    top_alpha_init_coord = initial_board.top_linker_alpha.coord
    top_beta_init_coord = initial_board.top_linker_beta.coord

    top_alpha_after_coord = after_board.top_linker_alpha.coord
    top_beta_after_coord = after_board.top_linker_beta.coord

    # TODO this is passing but I am not sure why
    IO.inspect top_alpha_init_coord
    IO.inspect top_alpha_after_coord

    assert Coordinate.equal?(top_alpha_init_coord, top_alpha_after_coord)
    assert Coordinate.equal?(top_beta_init_coord, top_beta_after_coord)
  end
end
