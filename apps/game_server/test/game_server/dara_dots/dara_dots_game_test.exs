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

    initial_count =
      initial_board.runner_pieces
      |> Map.keys()
      |> Enum.count()

    after_count =
      after_board.runner_pieces
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
    IO.inspect(top_alpha_init_coord)
    IO.inspect(top_alpha_after_coord)

    assert Coordinate.equal?(top_alpha_init_coord, top_alpha_after_coord)
    assert Coordinate.equal?(top_beta_init_coord, top_beta_after_coord)
  end

  test "new game should have no pending actions" do
    id = "test_8"
    {:ok, _pid} = DaraDotsGame.start(id)

    pending_actions = DaraDotsGame.get_pending_actions(id)
    assert map_size(pending_actions) == 0
  end

  test "save_pending_action should not save given non turn player" do
    # TODO spin down games after each set and then create a new one
    # to avoid all these tedious IDs and leftover games after tests
    id = "test_9"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "top_player")
    DaraDotsGame.add_player(id, "bot_player")

    DaraDotsGame.submit_move(id, "bot_player", 5, 5)

    pending_actions = DaraDotsGame.get_pending_actions(id)
    assert map_size(pending_actions) == 0
  end

  test "save_pending_action should save pending action given player turn" do
    id = "test_10"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "top_player")
    DaraDotsGame.add_player(id, "bot_player")

    DaraDotsGame.submit_move(id, "top_player", 1, 5)

    pending_actions = DaraDotsGame.get_pending_actions(id)
    assert map_size(pending_actions) == 1

    {action_kind, _, _, _} = pending_actions[1]
    assert action_kind == :move
  end

  test "placing a runner should not save pending action given not players turn" do
    id = "test_11"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "top_player")
    DaraDotsGame.add_player(id, "bot_player")

    DaraDotsGame.place_runner(id, "bot_player", 5, 3)

    pending_actions = DaraDotsGame.get_pending_actions(id)
    assert map_size(pending_actions) == 0
  end

  test "place_runner should add pending action given is players turn" do
    id = "test_12"
    {:ok, _pid} = DaraDotsGame.start(id)

    # Add both players
    DaraDotsGame.add_player(id, "top_player")
    DaraDotsGame.add_player(id, "bot_player")

    DaraDotsGame.place_runner(id, "top_player", 1, 5)

    pending_actions = DaraDotsGame.get_pending_actions(id)
    assert map_size(pending_actions) == 1

    {action_kind, _, _} = pending_actions[1]
    assert action_kind == :place_runner
  end

  test "save_pending_action should not save illegal pending moves" do
  end

  test "confirm_player_end_turn should not change turns given too few pending actions" do
  end

  test "confirm_player_end_turn should change turn given enough pending actions" do
  end

  test "confirm_player_end_turn should update board after changing turn" do
  end

  test "confirm_player_end_turn should clear pending actions" do
  end

  test "confirm_player_end_turn should broadcast new game state" do
  end
end
