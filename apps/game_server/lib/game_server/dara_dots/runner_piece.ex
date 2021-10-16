defmodule GameServer.DaraDots.RunnerPiece do
  alias __MODULE__
  alias GameServer.DaraDots.Coordinate

  defstruct [:coord, :facing, speed: 1]

  def new(start_coord, facing) when is_atom(facing) do
    {:ok, %RunnerPiece{coord: start_coord, facing: facing}}
  end

  def increase_speed(%RunnerPiece{} = runner) do
    cond do
      runner.speed < 5 ->
        %RunnerPiece{runner | speed: runner.speed + 1}

      true ->
        runner
    end
  end

  def decrease_speed(%RunnerPiece{} = runner) do
    cond do
      runner.speed > 1 ->
        %RunnerPiece{runner | speed: runner.speed - 1}

      true ->
        runner
    end
  end

  def reverse_facing(%RunnerPiece{} = runner) do
    case runner.facing do
      :up ->
        %RunnerPiece{runner | facing: :down}

      _ ->
        %RunnerPiece{runner | facing: :up}
    end
  end

  def move(%RunnerPiece{} = runner, %Coordinate{} = coord) do
    %RunnerPiece{runner | coord: coord}
  end

  def advance(%RunnerPiece{} = runner) do
    case runner.facing do
      :up ->
        advance_up(runner)

      :down ->
        advance_down(runner)
    end
  end

  defp advance_up(%RunnerPiece{} = runner) do
    new_row = runner.coord.row + runner.speed

    if new_row > Coordinate.get_max_row() do
      {:goal, :top_goal, runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, runner.coord.col)
      {:no_goal, move(runner, new_coord)}
    end
  end

  defp advance_down(%RunnerPiece{} = runner) do
    new_row = runner.coord.row - runner.speed

    if new_row < Coordinate.get_min_row() do
      {:goal, :bot_goal, runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, runner.coord.col)
      {:no_goal, move(runner, new_coord)}
    end
  end
end
