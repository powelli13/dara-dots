defmodule GameServer.SquarePiece do
  alias __MODULE__

  defstruct [:coord, :link_coords, possible_moves: MapSet.new()]

  def new(start_coord) do
    {:ok, %SquarePiece{coord: start_coord}}
  end
end
