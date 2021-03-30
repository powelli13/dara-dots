defmodule GameServer.TicTacToe do
  use GenServer
  alias Phoenix.PubSub

  @cross "X"
  @circle "O"

  @winning_indices [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6]
  ]

  def get_board_state(game_pid) do
    GenServer.call(game_pid, :get_board_state)
  end

  def get_current_turn(game_pid) do
    GenServer.call(game_pid, :get_current_turn)
  end

  def get_player_names(game_pid) do
    GenServer.call(game_pid, :get_player_names)
  end

  def set_circle_player(game_pid, player_name) when player_name != "" do
    GenServer.cast(game_pid, {:set_circle_name, player_name})
  end

  def set_cross_player(game_pid, player_name) when player_name != "" do
    GenServer.cast(game_pid, {:set_cross_name, player_name})
  end

  def make_move(game_pid, player_name, move_index) do
    GenServer.cast(game_pid, {:make_move, player_name, move_index})
  end

  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      game_id
    )
  end

  @impl GenServer
  def init(game_id) do
    Registry.register(GameServer.Registry, {__MODULE__, game_id}, game_id)

    # Board is laid out how it looks
    initial_state = %{
      :game_id => game_id,
      :current_turn => @cross,
      # TODO consider changing these to refs
      # generate GUIDs and put then on the sockets
      :players => %{
        :circle_player_name => "",
        :cross_player_name => ""
      },
      :board_state => %{
        0 => " ",
        1 => " ",
        2 => " ",
        3 => " ",
        4 => " ",
        5 => " ",
        6 => " ",
        7 => " ",
        8 => " "
      }
    }

    {:ok, initial_state}
  end

  @impl GenServer
  def handle_call(:get_board_state, _, game_state) do
    {:reply, game_state.board_state, game_state}
  end

  @impl GenServer
  def handle_call(:get_current_turn, _, game_state) do
    {:reply, game_state.current_turn, game_state}
  end

  @impl GenServer
  def handle_call(:get_player_names, _, game_state) do
    {
      :reply,
      %{
        :circle_player_name => game_state.players.circle_player_name,
        :cross_player_name => game_state.players.cross_player_name
      },
      game_state
    }
  end

  @impl GenServer
  def handle_cast({:set_circle_name, player_name}, game_state) do
    new_state =
      case game_state.players.circle_player_name do
        "" ->
          %{
            game_state
            | players:
                Map.put(
                  game_state.players,
                  :circle_player_name,
                  player_name
                )
          }

        _ ->
          game_state
      end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:set_cross_name, player_name}, game_state) do
    new_state =
      case game_state.players.cross_player_name do
        "" ->
          %{
            game_state
            | players:
                Map.put(
                  game_state.players,
                  :cross_player_name,
                  player_name
                )
          }

        _ ->
          game_state
      end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:make_move, player_name, move_index}, game_state) do
    IO.puts "before move"
    IO.inspect game_state.current_turn
    new_state =
      case valid_move?(game_state, move_index, player_name) do
        true ->
          IO.puts "Valid MOVE #{player_name}"
          perform_move(game_state, move_index)

        false ->
          IO.puts "Invalid MOVE #{player_name}"
          game_state
      end

    IO.puts "after move"
    IO.inspect new_state.current_turn

    # broadcast game state after successful move
    broadcast_board_state(new_state)

    # broadcast winner if there is one
    winner = check_victory_near_move(new_state.board_state, move_index)

    if winner != " " do
      broadcast_winner(game_state, winner)
    end

    {:noreply, new_state}
  end

  defp get_current_turn_player_name(game_state) do
    case game_state.current_turn do
      @cross ->
        game_state.players.cross_player_name

      @circle ->
        game_state.players.circle_player_name
    end
  end

  defp change_turn(game_state) do
    case game_state.current_turn do
      @cross ->
        %{
          game_state
          | current_turn: @circle
        }

      @circle ->
        %{
          game_state
          | current_turn: @cross
        }
    end
  end

  defp square_empty?(game_state, move_index) do
    game_state.board_state[move_index] == " "
  end

  defp valid_move?(game_state, move_index, player_name) do
    IO.puts "valid move. empty: #{square_empty?(game_state, move_index)}"
    IO.puts "valid move. player turn name: #{get_current_turn_player_name(game_state)}"
    square_empty?(game_state, move_index) &&
      get_current_turn_player_name(game_state) == player_name
  end

  defp perform_move(game_state, move_index) do
    new_state = %{
      game_state
      | board_state:
          Map.put(
            game_state.board_state,
            move_index,
            game_state.current_turn
          )
    }

    change_turn(new_state)
  end

  # Check for victories in the possible locations near 
  # the moved index
  defp check_victory_near_move(board_map, move_index) do
    possible_winners =
      @winning_indices
      |> Enum.filter(fn triplet -> Enum.member?(triplet, move_index) end)

    check_victory_possibles(possible_winners, board_map)
  end

  defp check_victory_possibles([check_indices | possible_winners], board_map) do
    triplet_match = check_victory_triplet(board_map, check_indices)

    if triplet_match != " " do
      triplet_match
    else
      check_victory_possibles(possible_winners, board_map)
    end
  end

  defp check_victory_possibles([], _) do
    " "
  end

  # Determine if a possible scoring triple is a victory and
  # return the winning piece if so, otherwise blank
  defp check_victory_triplet(board_map, [first, second, third]) do
    if board_map[first] == board_map[second] &&
         board_map[first] == board_map[third] &&
         board_map[second] == board_map[third] &&
         board_map[first] != " " do
      # Return the winner
      board_map[first]
    else
      " "
    end
  end

  defp broadcast_board_state(game_state) do
    broadcast_game_update(
      game_state.game_id,
      {:new_board_state, game_state.board_state}
    )
  end

  defp broadcast_winner(game_state, winner) do
    # TODO change this to use player id
    broadcast_game_update(
      game_state.game_id,
      {:game_winner, winner}
    )
  end

  defp broadcast_game_update(game_id, update_term) do
    PubSub.broadcast(GameServer.PubSub, "ttt_game:" <> game_id, update_term)
  end
end
