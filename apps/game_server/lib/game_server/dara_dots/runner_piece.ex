defmodule GameServer.DaraDots.RunnerPiece do
  alias __MODULE__
  alias GameServer.DaraDots.Coordinate

  defstruct [:coord, :facing, speed: 1]

  def new(start_coord, facing) when is_atom(facing) do
    {:ok, %RunnerPiece{coord: start_coord, facing: facing}}
  end

  def increase_speed(%RunnerPiece{} = runner) do
    cond do
      runner.speed < 5 ->
        %RunnerPiece{runner | speed: runner.speed + 1}

      true ->
        runner
    end
  end

  def decrease_speed(%RunnerPiece{} = runner) do
    cond do
      runner.speed > 1 ->
        %RunnerPiece{runner | speed: runner.speed - 1}

      true ->
        runner
    end
  end

  def reverse_facing(%RunnerPiece{} = runner) do
    case runner.facing do
      :up ->
        %RunnerPiece{runner | facing: :down}

      _ ->
        %RunnerPiece{runner | facing: :up}
    end
  end

  def move(%RunnerPiece{} = runner, %Coordinate{} = coord) do
    %RunnerPiece{runner | coord: coord}
  end

  # for runner:
  # use current speed for starting speed
  # check for link on current coord
  # if link then move to other link coord and dec working speed
  # change facing
  # else advance up or down row depending on facing and dec working speed
  # continue until working speed is 0

  def advance(%RunnerPiece{} = runner, link_coords) do
    advance_step(runner, link_coords, runner.speed)
  end

  # TODO problem with this implementation the runner will immediately move back on the link
  defp advance_step(%RunnerPiece{} = runner, link_coords, trip_speed) do
    # Determine if the runner is currently on a link
    current_links =
      link_coords
      |> Enum.filter(fn link ->
        MapSet.member?(link, runner.coord)
      end)

    case current_links do
      # Not on a link so use standard advancing
      # Standard advancing may score so check that
      [] ->
        advanced_result = advance_standard(runner)

        # if no goal keep advancing with decrimented speed
        # otherwise return goal
        case advanced_result do
          {:no_goal, new_runner} ->
            advance_step(new_runner, link_coords, trip_speed - 1)

          {:goal, scored_goal, new_runner} ->
            {:goal, scored_goal, new_runner}
        end

      # On a link so we cross it, increase runner speed,
      # and change facing
      hit_links ->
        advance_link(runner, hit_links, link_coords, trip_speed)
    end
  end

  defp advance_step(%RunnerPiece{} = runner, link_coords, 0) do
    {:no_goal, runner}
  end

  defp advance_link(%RunnerPiece{} = runner, hit_links, link_coords, trip_speed) do
    current_link = hd(hit_links |> MapSet.to_list())

    # TODO it would be nice to use MapSet.difference here
    # but Coordinate doesn't implement Enumerable so we can't
    # current_link here will be a list of two coordinates
    other_coord =
      Enum.reduce(current_link, nil, fn c, _acc ->
        if Coordinate.equal?(c, runner.coord), do: nil, else: c
      end)

    # If other_coord is nil here we have bad data
    # Move to the other coord in the link,
    # increase speed and change facing
    # Keep advancing with less speed for the trip
    runner
    |> move(other_coord)
    |> reverse_facing()
    |> increase_speed()
    |> advance_step(link_coords, trip_speed - 1)
  end

  defp advance_standard(%RunnerPiece{} = runner) do
    case runner.facing do
      :up ->
        advance_up(runner)

      :down ->
        advance_down(runner)
    end
  end

  defp advance_up(%RunnerPiece{} = runner) do
    new_row = runner.coord.row + 1

    if new_row > Coordinate.get_max_row() do
      {:goal, :top_goal, runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, runner.coord.col)
      {:no_goal, move(runner, new_coord)}
    end
  end

  defp advance_down(%RunnerPiece{} = runner) do
    new_row = runner.coord.row - 1

    if new_row < Coordinate.get_min_row() do
      {:goal, :bot_goal, runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, runner.coord.col)
      {:no_goal, move(runner, new_coord)}
    end
  end
end
