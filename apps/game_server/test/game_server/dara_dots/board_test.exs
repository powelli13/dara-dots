defmodule GameServer.DaraDots.BoardTest do
  use ExUnit.Case, async: true

  alias GameServer.DaraDots.{Board, Coordinate, RunnerPiece}

  test "placed runner should face up given first row" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(1, 1) do
      placed_board = Board.place_runner(board, coord)

      {_, placed_runner} = placed_board.runner_pieces |> Map.to_list() |> hd

      assert placed_runner.facing == :up
    end
  end

  test "placed runner should face down given last row" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(5, 1) do
      placed_board = Board.place_runner(board, coord)

      {_, placed_runner} = placed_board.runner_pieces |> Map.to_list() |> hd

      assert placed_runner.facing == :down
    end
  end

  test "placing a runner should advance the timer" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(1, 1) do
      start_timer = board.runner_timer

      placed_board = Board.place_runner(board, coord)

      assert placed_board.runner_timer == start_timer + 1
    end
  end

  test "should not create runner if placed outside starting rows" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(3, 1) do
      placed_board = Board.place_runner(board, coord)

      assert map_size(placed_board.runner_pieces) == 0
    end
  end

  test "place runner should error if placed on node with a runner" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(1, 3) do
      # Place initial runner
      placed_board = Board.place_runner(board, coord)

      # Try to place the second runner
      invalid_attempt_board = Board.place_runner(placed_board, coord)

      assert map_size(invalid_attempt_board.runner_pieces) == 1
    end
  end

  test "place runner should allow different columns but not same" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord_first} <- Coordinate.new(5, 1),
         {:ok, coord_second} <- Coordinate.new(5, 3) do
      placed_board = Board.place_runner(board, coord_first)

      assert map_size(placed_board.runner_pieces) == 1

      second_placed_board = Board.place_runner(placed_board, coord_second)

      assert map_size(second_placed_board.runner_pieces) == 2

      third_placed_board = Board.place_runner(second_placed_board, coord_first)

      assert map_size(third_placed_board.runner_pieces) == 2
    end
  end

  test "place runner should allow placing in same column but separate rows" do
    with {:ok, board} <- Board.new_test(),
         {:ok, top_row} <- Coordinate.new(1, 3),
         {:ok, bot_row} <- Coordinate.new(5, 3) do
      placed_board =
        board
        |> Board.place_runner(top_row)
        |> Board.place_runner(bot_row)

      assert map_size(placed_board.runner_pieces) == 2
    end
  end

  test "place runner should allow placing in three separate columns" do
    with {:ok, board} <- Board.new_test(),
         {:ok, first_col} <- Coordinate.new(1, 1),
         {:ok, second_col} <- Coordinate.new(1, 2),
         {:ok, third_col} <- Coordinate.new(1, 3) do
      first_placement = Board.place_runner(board, first_col)

      assert map_size(first_placement.runner_pieces) == 1

      second_placement = Board.place_runner(first_placement, second_col)

      assert map_size(second_placement.runner_pieces) == 2

      third_placement = Board.place_runner(second_placement, third_col)

      assert map_size(third_placement.runner_pieces) == 3
    end
  end

  test "scoring in top goal should increase bot player score" do
    with {:ok, board} <- Board.new_test() do
      scored_board = Board.score_goal(board, :bot_goal)
      assert scored_board.top_player_score == 1
    end
  end

  test "scoring in bot goal should increase top player score" do
    with {:ok, board} <- Board.new_test() do
      scored_board = Board.score_goal(board, :top_goal)
      assert scored_board.bot_player_score == 1
    end
  end

  test "advance all runners should move all" do
    with {:ok, board} <- Board.new_test(),
         {:ok, first_coord} <- Coordinate.new(1, 3),
         {:ok, second_coord} <- Coordinate.new(5, 3),
         {:ok, first_expected} <- Coordinate.new(2, 3),
         {:ok, second_expected} <- Coordinate.new(4, 3) do
      placed_board =
        board
        |> Board.place_runner(first_coord)
        |> Board.place_runner(second_coord)

      assert Enum.count(placed_board.runner_pieces) == 2

      advanced_board = Board.advance_runners(placed_board)

      runner_coords_mapset =
        advanced_board.runner_pieces
        |> Enum.map(fn {_entry_time, runner} ->
          runner.coord
        end)
        |> MapSet.new()

      expected_coords_mapset = MapSet.new([first_expected, second_expected])

      assert MapSet.equal?(runner_coords_mapset, expected_coords_mapset)
    end
  end

  test "advance bot runner to end should score" do
    with {:ok, board} <- Board.new_test(),
         {:ok, first_coord} <- Coordinate.new(1, 3) do
      scored_board =
        board
        |> Board.place_runner(first_coord)
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()

      assert Enum.count(scored_board.runner_pieces) == 0
      assert scored_board.top_player_score == 0
      assert scored_board.bot_player_score == 1
    end
  end

  test "advance top runner to end should score" do
    with {:ok, board} <- Board.new_test(),
         {:ok, first_coord} <- Coordinate.new(5, 3) do
      scored_board =
        board
        |> Board.place_runner(first_coord)
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()
        |> Board.advance_runners()

      assert Enum.count(scored_board.runner_pieces) == 0
      assert scored_board.top_player_score == 1
      assert scored_board.bot_player_score == 0
    end
  end

  test "current_turn should start for top player" do
    with {:ok, board} <- Board.new_test() do
      assert Board.is_top_turn?(board)
    end
  end

  test "change_turn should update turn" do
    with {:ok, board} <- Board.new_test() do
      assert board.current_turn == :top_player

      new_board = Board.change_turn(board)

      assert new_board.current_turn == :bot_player

      last_board = Board.change_turn(new_board)

      assert last_board.current_turn == :top_player
    end
  end

  # TODO tests for movable coords and linkable coords
  test "should be bot turn after a move is made" do
    with {:ok, board} <- Board.new_test(),
         {:ok, top_dest_coord} <- Coordinate.new(5, 1) do
      moved_board =
        Board.move_linker_no_link(
          board,
          :top_player,
          :top_linker_alpha,
          top_dest_coord
        )

      assert moved_board.current_turn == :bot_player
    end
  end

  test "should not move bot linker if it is top turn" do
    with {:ok, board} <- Board.new_test(),
         {:ok, bot_alpha_start} <- Coordinate.new(1, 2),
         {:ok, bot_dest_coord} <- Coordinate.new(1, 1) do
      moved_board =
        Board.move_linker_no_link(
          board,
          :bot_player,
          :bot_linker_alpha,
          bot_dest_coord
        )

      assert moved_board.current_turn == :top_player
      assert Coordinate.equal?(bot_alpha_start, moved_board.bot_linker_alpha.coord)
    end
  end

  test "moving linker and link should not move if it is not their turn" do
    with {:ok, board} <- Board.new_test(),
         {:ok, bot_alpha_start} <- Coordinate.new(1, 2),
         {:ok, bot_dest_coord} <- Coordinate.new(1, 1) do
      moved_board =
        Board.move_linker_and_link(
          board,
          :bot_player,
          :bot_linker_alpha,
          bot_dest_coord
        )

      assert moved_board.current_turn == :top_player
      assert Coordinate.equal?(bot_alpha_start, moved_board.bot_linker_alpha.coord)
    end
  end

  test "should not advance runners if it is not the players turn" do
    with {:ok, board} <- Board.new_test(),
         {:ok, bot_dest_coord} <- Coordinate.new(1, 1),
         {:ok, runner_coord} <- Coordinate.new(1, 3) do
      moved_board =
        Board.move_linker_and_link(
          board,
          :bot_player,
          :bot_linker_alpha,
          bot_dest_coord
        )
        |> Board.place_runner(runner_coord)

      assert moved_board.current_turn == :top_player

      [{_age, runner}] = moved_board.runner_pieces |> Map.to_list()
      assert Coordinate.equal?(runner_coord, runner.coord)
    end
  end

  test "after advancing runners runners should remain a map" do
    with {:ok, board} <- Board.new_test(),
         {:ok, coord} <- Coordinate.new(1, 1) do
      start_timer = board.runner_timer

      placed_board = Board.place_runner(board, coord)

      assert is_map(placed_board.runner_pieces)

      advanced_board = Board.advance_runners(placed_board)

      assert is_map(advanced_board.runner_pieces)
    end
  end

  test "should be able to place a runner after placing and moving" do
    with {:ok, board} <- Board.new_test(),
         {:ok, runner_coord} <- Coordinate.new(1, 1),
         {:ok, linker_dest_coord} <- Coordinate.new(4, 2) do
      board = Board.place_runner(board, runner_coord)

      assert is_map(board.runner_pieces)

      board =
        Board.move_linker_and_link(
          board,
          :top_player,
          :top_linker_alpha,
          linker_dest_coord
        )

      assert is_map(board.runner_pieces)

      board = Board.place_runner(board, runner_coord)

      assert is_map(board.runner_pieces)
    end
  end

  test "should be able to place multiple runners then move and place again" do
    with {:ok, board} <- Board.new_test(),
         {:ok, runner_coord} <- Coordinate.new(1, 1),
         {:ok, second_runner_coord} <- Coordinate.new(1, 3),
         {:ok, linker_dest_coord} <- Coordinate.new(4, 2) do
      board = Board.place_runner(board, runner_coord)
      board = Board.place_runner(board, second_runner_coord)

      assert is_map(board.runner_pieces)

      board =
        Board.move_linker_no_link(
          board,
          :top_player,
          :top_linker_alpha,
          linker_dest_coord
        )

      assert Coordinate.equal?(linker_dest_coord, board.top_linker_alpha.coord)

      assert is_map(board.runner_pieces)

      board = Board.place_runner(board, runner_coord)

      assert is_map(board.runner_pieces)
    end
  end

  test "clearing animate paths should leave runners as a map" do
    with {:ok, board} <- Board.new_test() do
      board = Board.clear_runner_animate_paths(board)

      assert is_map(board.runner_pieces)
    end
  end

  test "top player should only match top pieces" do
    assert Board.is_players_piece?(:top_player, :top_linker_alpha)
    assert Board.is_players_piece?(:top_player, :top_linker_beta)
  end

  test "top player should not match bot pieces" do
    assert Board.is_players_piece?(:top_player, :bot_linker_alpha) == false
    assert Board.is_players_piece?(:top_player, :bot_linker_beta) == false
  end

  test "bot player should only match bot pieces" do
    assert Board.is_players_piece?(:bot_player, :bot_linker_alpha)
    assert Board.is_players_piece?(:bot_player, :bot_linker_beta)
  end

  test "bot player should not match top pieces" do
    assert Board.is_players_piece?(:bot_player, :top_linker_alpha) == false
    assert Board.is_players_piece?(:bot_player, :top_linker_beta) == false
  end
end
