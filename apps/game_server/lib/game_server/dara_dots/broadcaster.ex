defmodule GameServer.DaraDots.Broadcaster do
  @moduledoc """
  State transformation and broadcasting for Dara Dots game.
  """
  alias Phoenix.PubSub
  alias GameServer.DaraDots.{Board, Coordinate}

  def broadcast_game_state(state) do
    # generate the game state to be broadcast
    state_to_broadcast = %{
      :dots =>
        Enum.map(
          state.board.dot_coords,
          fn coord -> coord |> Coordinate.to_list() end
        ),
      :bot_alpha => state.board.bot_linker_alpha.coord |> Coordinate.to_list(),
      :bot_beta => state.board.bot_linker_beta.coord |> Coordinate.to_list(),
      :top_alpha => state.board.top_linker_alpha.coord |> Coordinate.to_list(),
      :top_beta => state.board.top_linker_beta.coord |> Coordinate.to_list(),
      :top_player_score => state.board.top_player_score,
      :bot_player_score => state.board.bot_player_score,
      :movable_dots =>
        Enum.map(
          Board.get_movable_coords(state.board, state.selected_piece) |> MapSet.to_list(),
          fn coord -> Coordinate.to_list(coord) end
        ),
      :linkable_dots =>
        Enum.map(
          Board.get_linkable_coords(state.board, state.selected_piece) |> MapSet.to_list(),
          fn coord -> Coordinate.to_list(coord) end
        ),
      :runner_pieces =>
        Enum.map(
          state.board.runner_pieces,
          fn {_ix, runner} ->
            %{coords: Coordinate.to_list(runner.coord), facing: to_string(runner.facing)}
          end
        ),
      # TODO does it matter if the links are not tied to specific linkers?
      # I was thinking about this more the other day and a visual indicator
      # may be nice to have. That way the user will know which of their links
      # will go away if they make a new link
      :links =>
        Board.get_all_link_coords(state.board)
        |> Enum.map(fn coord_map_set ->
          coord_map_set
          |> MapSet.to_list()
          |> Enum.map(fn c ->
            Coordinate.to_list(c)
          end)
        end),
      state.top_player_id => "#{state.top_player_id} hey top player this is your message",
      state.bot_player_id => "#{state.bot_player_id} hey bot player this is your message",
      # TODO may need to make this a string
      :current_turn => state.board.current_turn
    }

    PubSub.broadcast(
      GameServer.PubSub,
      "dara_dots_game:#{state.game_id}",
      {:new_game_state, state_to_broadcast}
    )
  end
end