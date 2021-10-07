defmodule GameServer.DaraDots.Board do
  alias __MODULE__
  alias GameServer.DaraDots.{Coordinate, LinkerPiece}

  defstruct [
    :top_linker_alpha,
    :top_linker_beta,
    :bot_linker_alpha,
    :bot_linker_beta,
    :circle_piece,
    dot_coords: MapSet.new()]

  def new() do
    with 
      {:ok, circle_start_coord} <- Coordinate.new(2, 2),
      {:ok, circle_piece} <- LinkerPiece.new(circle_start_coord)
    do
      {:ok,
      %Board{
        circle_piece: circle_piece,
        dot_coords: MapSet.new(build_grid_coords())
      }}
    else
      {:error, "Failed to initialize the board"}
    end

  end

  defp build_grid_coords() do
    Enum.map(1..5, fn n -> Enum.map(1..5, fn i -> {n, i} end) end)
    |> List.flatten()
    |> Enum.map(fn {row, col} ->
      {:ok, coord} = Coordinate.new(row, col)
      coord
    end)
  end
end
