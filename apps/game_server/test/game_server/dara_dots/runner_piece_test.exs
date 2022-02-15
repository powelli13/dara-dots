defmodule GameServer.DaraDots.RunnerPieceTest do
  use ExUnit.Case, async: true

  alias GameServer.DaraDots.{RunnerPiece, Coordinate}

  setup do
    {:ok, coord} = Coordinate.new(1, 1)
    {:ok, runner} = RunnerPiece.new(coord, :up)

    {:ok, runner: runner}
  end

  test "start speed should be one", state do
    assert state[:runner].speed == 1
  end

  test "increase speed should add one", state do
    start_speed = state[:runner].speed

    inc_runner = RunnerPiece.increase_speed(state[:runner])

    assert inc_runner > start_speed
    assert inc_runner.speed == start_speed + 1
  end

  test "increase speed should not exceed five", state do
    inc_runner =
      state[:runner]
      |> RunnerPiece.increase_speed()
      |> RunnerPiece.increase_speed()
      |> RunnerPiece.increase_speed()
      |> RunnerPiece.increase_speed()
      |> RunnerPiece.increase_speed()
      |> RunnerPiece.increase_speed()

    assert inc_runner.speed == 5
  end

  test "decrease speed should subtract one" do
    {:ok, coord} = Coordinate.new(1, 1)
    {:ok, runner} = RunnerPiece.new(coord, :up)

    inc_runner = RunnerPiece.increase_speed(runner)

    assert inc_runner.speed == 2

    dec_runner = RunnerPiece.decrease_speed(inc_runner)

    assert dec_runner.speed == 1
  end

  test "decrease speed should not go below one", state do
    dec_runner =
      state[:runner]
      |> RunnerPiece.decrease_speed()
      |> RunnerPiece.decrease_speed()
      |> RunnerPiece.decrease_speed()
      |> RunnerPiece.decrease_speed()
      |> RunnerPiece.decrease_speed()
      |> RunnerPiece.decrease_speed()

    assert dec_runner.speed == 1
  end

  test "reverse facing going up should go down" do
    with {:ok, coord} <- Coordinate.new(1, 1),
         {:ok, up_runner} <- RunnerPiece.new(coord, :up) do
      down_runner = RunnerPiece.reverse_facing(up_runner)

      assert down_runner.facing == :down
    end
  end

  test "reverse facing going down should go up" do
    with {:ok, coord} <- Coordinate.new(1, 1),
         {:ok, down_runner} <- RunnerPiece.new(coord, :down) do
      up_runner = RunnerPiece.reverse_facing(down_runner)

      assert up_runner.facing == :up
    end
  end

  test "advancing up should score when in range" do
    with {:ok, start_coord} <- Coordinate.new(5, 1),
         {:ok, runner} <- RunnerPiece.new(start_coord, :up) do
      {was_goal, goal, _moved_runner} = RunnerPiece.advance(runner, [])

      assert was_goal == :goal
      assert goal == :top_goal
    end
  end

  test "advancing up should not score when out of range" do
    with {:ok, start_coord} <- Coordinate.new(1, 1),
         {:ok, runner} <- RunnerPiece.new(start_coord, :up) do
      {was_goal, moved_runner} = RunnerPiece.advance(runner, [])

      assert was_goal == :no_goal
      assert moved_runner.coord.row == start_coord.row + runner.speed
    end
  end

  test "advancing down should score when in range" do
    with {:ok, start_coord} <- Coordinate.new(1, 1),
         {:ok, runner} <- RunnerPiece.new(start_coord, :down) do
      {was_goal, goal, _moved_runner} = RunnerPiece.advance(runner, [])

      assert was_goal == :goal
      assert goal == :bot_goal
    end
  end

  test "advancing down should not score when out of range" do
    with {:ok, start_coord} <- Coordinate.new(5, 1),
         {:ok, runner} <- RunnerPiece.new(start_coord, :down) do
      {was_goal, moved_runner} = RunnerPiece.advance(runner, [])

      assert was_goal == :no_goal
      assert moved_runner.coord.row == start_coord.row - runner.speed
    end
  end

  test "advance up should change direction and follow link" do
    with {:ok, runner_coord} <- Coordinate.new(2, 2),
         {:ok, link_first} <- Coordinate.new(2, 2),
         {:ok, link_second} <- Coordinate.new(2, 3),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :up) do
      link_coords = [MapSet.new([link_first, link_second])]
      {was_goal, moved_runner} = RunnerPiece.advance(runner, link_coords)

      assert was_goal == :no_goal
      assert Coordinate.equal?(moved_runner.coord, link_second)
      assert moved_runner.facing == :down
      assert moved_runner.speed == runner.speed + 1
    end
  end

  test "advance down should change direction and follow link" do
    with {:ok, runner_coord} <- Coordinate.new(4, 4),
         {:ok, link_first} <- Coordinate.new(4, 4),
         {:ok, link_second} <- Coordinate.new(4, 5),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :down) do
      link_coords = [MapSet.new([link_first, link_second])]
      {was_goal, moved_runner} = RunnerPiece.advance(runner, link_coords)

      assert was_goal == :no_goal
      assert Coordinate.equal?(moved_runner.coord, link_second)
      assert moved_runner.facing == :up
      assert moved_runner.speed == runner.speed + 1
    end
  end

  test "advance should not take link when not on link" do
    with {:ok, runner_coord} <- Coordinate.new(3, 3),
         {:ok, link_first} <- Coordinate.new(4, 4),
         {:ok, link_second} <- Coordinate.new(4, 5),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :up) do
      link_coords = [MapSet.new([link_first, link_second])]
      {was_goal, moved_runner} = RunnerPiece.advance(runner, link_coords)

      assert was_goal == :no_goal
      assert moved_runner.coord.row == runner_coord.row + 1
      assert moved_runner.coord.col == runner_coord.col
      assert moved_runner.facing == :up
      assert moved_runner.speed == runner.speed
    end
  end

  test "should not take link immediately after taking a link" do
    with {:ok, runner_coord} <- Coordinate.new(3, 3),
         {:ok, link_first} <- Coordinate.new(3, 3),
         {:ok, link_second} <- Coordinate.new(3, 4),
         {:ok, expected_dest} <- Coordinate.new(4, 4),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :down) do
      # speed up the runner so it moves two nodes
      fast_runner = RunnerPiece.increase_speed(runner)
      link_coords = [MapSet.new([link_first, link_second])]
      {_was_goal, moved_runner} = RunnerPiece.advance(fast_runner, link_coords)

      assert Coordinate.equal?(moved_runner.coord, expected_dest)
    end
  end

  test "should take link after a standard move" do
    with {:ok, runner_coord} <- Coordinate.new(2, 3),
         {:ok, link_first} <- Coordinate.new(3, 3),
         {:ok, link_second} <- Coordinate.new(3, 4),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :up) do
      # speed up the runner so it moves two nodes
      fast_runner = RunnerPiece.increase_speed(runner)
      link_coords = [MapSet.new([link_first, link_second])]
      {_was_goal, moved_runner} = RunnerPiece.advance(fast_runner, link_coords)

      assert Coordinate.equal?(moved_runner.coord, link_second)
    end
  end

  test "should advance given no links" do
    with {:ok, runner_coord} <- Coordinate.new(3, 3),
         {:ok, expected_dest} <- Coordinate.new(4, 3),
         {:ok, runner} <- RunnerPiece.new(runner_coord, :up) do
      {_was_goal, moved_runner} = RunnerPiece.advance(runner, [])

      assert Coordinate.equal?(moved_runner.coord, expected_dest)
    end
  end
end
