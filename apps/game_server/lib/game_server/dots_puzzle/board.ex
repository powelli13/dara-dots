defmodule DaraDots.Board do
  alias __MODULE__

  defstruct dot_coordinates: MapSet.new()

  def new_grid() do
    {:ok, %Board{}}
  end
end
