defmodule GameServer.DaraDots.BoardTest do
  use ExUnit.Case, async: true

  alias GameServer.DaraDots.{Board, Coordinate, RunnerPiece}

  test "placed runner should face up given first row" do
    with {:ok, board} <- Board.new(),
         {:ok, coord} <- Coordinate.new(1, 1) do
      placed_board = Board.place_runner(board, coord)

      {_, placed_runner} = placed_board.runner_pieces |> Map.to_list() |> hd

      assert placed_runner.facing == :up
    end
  end

  test "placed runner should face down given last row" do
    with {:ok, board} <- Board.new(),
         {:ok, coord} <- Coordinate.new(5, 1) do
      placed_board = Board.place_runner(board, coord)

      {_, placed_runner} = placed_board.runner_pieces |> Map.to_list() |> hd

      assert placed_runner.facing == :down
    end
  end

  test "placing a runner should advance the timer" do
    with {:ok, board} <- Board.new(),
         {:ok, coord} <- Coordinate.new(1, 1) do
      start_timer = board.runner_timer

      placed_board = Board.place_runner(board, coord)

      assert placed_board.runner_timer == start_timer + 1
    end
  end

  test "should error if runner placed outside starting rows" do
    with {:ok, board} <- Board.new(),
         {:ok, coord} <- Coordinate.new(3, 1) do
      assert_raise FunctionClauseError, fn ->
        _ = Board.place_runner(board, coord)
      end
    end
  end

  test "advance all runners should move all" do
    with {:ok, board} <- Board.new(),
         {:ok, first_coord} <- Coordinate.new(1, 3),
         {:ok, second_coord} <- Coordinate.new(5, 3),
         {:ok, first_expected} <- Coordinate.new(2, 3),
         {:ok, second_expected} <- Coordinate.new(4, 3) do
      placed_board = 
        board
        |> Board.place_runner(first_coord)
        |> Board.place_runner(second_coord)
      IO.inspect placed_board.runner_pieces

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
end
