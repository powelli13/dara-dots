defmodule GameServer.Board do
  alias __MODULE__
  alias GameServer.Coordinate

  defstruct [:circle_piece, dot_coords: MapSet.new()]

  def new() do
    {:ok, %Board{dot_coords: MapSet.new(build_grid_coords())}}
  end

  defp build_grid_coords() do
    Enum.map(1..9, fn n -> Enum.map(1..9, fn i -> {n, i} end) end)
    |> List.flatten()
    |> Enum.map(fn {row, col} ->
      {:ok, coord} = Coordinate.new(row, col)
      coord
    end)
  end
end
