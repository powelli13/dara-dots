defmodule GameServer.Piece do
  alias __MODULE__

  defstruct [:shape, :coord, possible_moves: MapSet.new()]

  def new(shape, start_coord) when is_atom(shape) do
    {:ok, %Piece{shape: shape, coord: start_coord}}
  end
end
