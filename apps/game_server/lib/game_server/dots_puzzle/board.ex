defmodule GameServer.Board do
  alias __MODULE__
  alias GameServer.{Coordinate, Piece}

  defstruct [:circle_piece, dot_coords: MapSet.new()]

  def new() do
    {:ok, circle_start_coord} = Coordinate.new(2, 2)
    {:ok, circle_piece} = Piece.new(:circle, circle_start_coord)

    {:ok,
     %Board{
       circle_piece: circle_piece,
       dot_coords: MapSet.new(build_grid_coords())
     }}
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
