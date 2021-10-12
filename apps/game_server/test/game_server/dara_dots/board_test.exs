defmodule GameServer.DaraDots.BoardTest do
  use ExUnit.Case, async: true

  alias GameServer.DaraDots.{Board, Coordinate}

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
end
