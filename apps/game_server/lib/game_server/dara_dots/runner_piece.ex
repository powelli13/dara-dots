defmodule GameServer.DaraDots.RunnerPiece do
  alias __MODULE__

  defstruct [:coord, :facing, speed: 1]

  def new(start_coord, facing) do
    {:ok, %RunnerPiece{coord: start_coord, facing: facing}}
  end
end
