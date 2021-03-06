defmodule GameServer.TicTacToe do
  use GenServer

  @cross "X"
  @circle "O"

  def get_board_state(game_pid) do
    GenServer.call(game_pid, :get_board_state)
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
    # TODO needed for when channels start looking us up
    # Registry.register(GameServer.Registry, {__MODULE__, game_id}, game_id)

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
    new_state =
      case valid_move?(game_state, move_index, player_name) do
        true ->
          perform_move(game_state, move_index)

        false ->
          game_state
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
end
