defmodule GameServer.TicTacToe do
  use GenServer

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
      # TODO consider changing these to refs
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
    board_as_list =
      game_state[:board_state]
      |> Enum.map(fn {_, sq} -> sq end)

    {:reply, board_as_list, game_state}
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
          # TODO is there a more elegant way to do this in Elixir
          Map.put(
            game_state,
            :players,
            Map.put(
              game_state.players,
              :circle_player_name,
              player_name
            )
          )

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
          # TODO is there a more elegant way to do this in Elixir
          Map.put(
            game_state,
            :players,
            Map.put(
              game_state.players,
              :cross_player_name,
              player_name
            )
          )

        _ ->
          game_state
      end

    {:noreply, new_state}
  end
end
