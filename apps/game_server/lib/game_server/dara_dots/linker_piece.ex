defmodule GameServer.DaraDots.LinkerPiece do
  alias __MODULE__

  defstruct [:coord, link_coords: MapSet.new(), possible_moves: MapSet.new()]

  def new(start_coord) do
    {:ok, %LinkerPiece{coord: start_coord}}
  end
end
