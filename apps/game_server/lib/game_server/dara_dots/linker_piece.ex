defmodule GameServer.DaraDots.LinkerPiece do
  alias __MODULE__
  alias GameServer.DaraDots.Coordinate

  defstruct [:coord, link_coords: nil]

  def new(start_coord) do
    {:ok, %LinkerPiece{coord: start_coord}}
  end

  def set_link(
        %LinkerPiece{} = linker,
        %Coordinate{} = start,
        %Coordinate{} = finish
      ) do
    cond do
      start.row == finish.row &&
          abs(start.col - finish.col) == 1 ->
        %LinkerPiece{linker | link_coords: MapSet.new([start, finish])}

      true ->
        linker
    end
  end

  def remove_link(%LinkerPiece{} = linker) do
    %LinkerPiece{linker | link_coords: nil}
  end

  def move(%LinkerPiece{} = linker, %Coordinate{} = coord) do
    %LinkerPiece{linker | coord: coord}
  end

  def move_and_set_link(%LinkerPiece{} = linker, %Coordinate{} = dest_coord) do
    updated_link = set_link(linker, linker.coord, dest_coord)

    %LinkerPiece{updated_link | coord: dest_coord}
  end
end
