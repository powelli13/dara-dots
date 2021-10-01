defmodule GameServer.TrianglePiece do
  alias __MODULE__

  defstruct [:coord]

  def new(start_coord) do
    {:ok, %TrianglePiece{coord: start_coord}}
  end
end