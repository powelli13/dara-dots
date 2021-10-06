defmodule GameServer.DaraDots.LinkerPiece do
  alias __MODULE__
  alias GameServer.DaraDots.Coordinate

  defstruct [:coord, link_coords: nil, possible_moves: MapSet.new()]

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
end
