defmodule GameServer.DaraDots.RunnerPiece do
  alias __MODULE__

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
end
