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
end
