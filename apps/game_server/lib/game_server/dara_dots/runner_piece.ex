defmodule GameServer.DaraDots.RunnerPiece do
  alias __MODULE__
  alias GameServer.DaraDots.Coordinate

  # last_step_link keeps track of whether the most recent move
  # was on a link to avoid taking the same link twice
  defstruct [
    :coord,
    :facing,
    speed: 1,
    last_step_link: false,
    animate_path: []
  ]

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

  def get_path_to_animate(%RunnerPiece{} = runner) do
    runner.animate_path
  end

  def reset_path_to_animate(%RunnerPiece{} = runner) do
    %RunnerPiece{runner | animate_path: []}
  end

  def advance(%RunnerPiece{} = runner, link_coords) do
    advance_step(runner, link_coords, runner.speed)
  end

  # TODO rename restructure this
  defp move(%RunnerPiece{} = runner, %Coordinate{} = coord) do
    runner_and_path = add_path_piece(runner, coord)
    %RunnerPiece{runner_and_path | coord: coord}
  end

  defp add_path_piece(%RunnerPiece{} = runner, %Coordinate{} = coord) do
    # TODO consider moving this transformation to the broadcaster?
    piece_map = %{
      "start" => Coordinate.to_list(runner.coord),
      "end" => Coordinate.to_list(coord)
    }

    %RunnerPiece{runner | animate_path: [piece_map | runner.animate_path]}
  end

  defp moved_link(%RunnerPiece{} = runner) do
    %RunnerPiece{runner | last_step_link: true}
  end

  defp moved_standard(%RunnerPiece{} = runner) do
    %RunnerPiece{runner | last_step_link: false}
  end

  defp advance_step(%RunnerPiece{} = runner, link_coords, trip_speed) when trip_speed > 0 do
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
        handle_advance_standard(runner, link_coords, trip_speed)

      # On a link so we cross it, increase runner speed,
      # and change facing
      hit_links ->
        if not runner.last_step_link do
          advance_link(runner, hit_links, link_coords, trip_speed)
        else
          handle_advance_standard(runner, link_coords, trip_speed)
        end
    end
  end

  defp advance_step(%RunnerPiece{} = runner, _link_coords, 0) do
    {:no_goal, runner}
  end

  defp advance_link(%RunnerPiece{} = runner, hit_links, link_coords, trip_speed) do
    [first_link_coord, second_link_coord] = hd(hit_links) |> MapSet.to_list()

    other_coord =
      if Coordinate.equal?(runner.coord, first_link_coord),
        do: second_link_coord,
        else: first_link_coord

    # Move to the other coord in the link,
    # increase speed and change facing
    # Keep advancing with less speed for the trip
    runner
    |> move(other_coord)
    |> moved_link()
    |> reverse_facing()
    |> increase_speed()
    |> advance_step(link_coords, trip_speed - 1)
  end

  # if no goal keep advancing with decrimented speed
  # otherwise return goal
  defp handle_advance_standard(
         %RunnerPiece{} = runner,
         link_coords,
         trip_speed
       ) do
    case advance_standard(runner) do
      {:no_goal, new_runner} ->
        advance_step(new_runner, link_coords, trip_speed - 1)

      {:goal, scored_goal, new_runner} ->
        {:goal, scored_goal, new_runner}
    end
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

    new_runner = moved_standard(runner)

    if new_row > Coordinate.get_max_row() do
      {:goal, :top_goal, new_runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, new_runner.coord.col)
      {:no_goal, move(new_runner, new_coord)}
    end
  end

  defp advance_down(%RunnerPiece{} = runner) do
    new_row = runner.coord.row - 1

    new_runner = moved_standard(runner)

    if new_row < Coordinate.get_min_row() do
      {:goal, :bot_goal, new_runner}
    else
      {:ok, new_coord} = Coordinate.new(new_row, new_runner.coord.col)
      {:no_goal, move(new_runner, new_coord)}
    end
  end
end
