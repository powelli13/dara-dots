defmodule GameServerWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "lobby:*", GameServerWeb.LobbyChannel

  channel "rps_lobby:*", GameServerWeb.RpsLobbyChannel
  channel "rps_game:*", GameServerWeb.RpsGameChannel

  channel "ttt_lobby:*", GameServerWeb.TttLobbyChannel
  channel "ttt_game:*", GameServerWeb.TttGameChannel

  channel "pong_game:*", GameServerWeb.PongGameChannel

  channel "dara_dots_game:*", GameServerWeb.DaraDotsGameChannel

  # Generic lobby chat
  channel "lobby_chat:*", GameServerWeb.GenericLobbyChatChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(
           socket,
           "user socket",
           token,
           max_age: 1_209_600
         ) do
      {:ok, player_id} ->
        {:ok, assign(socket, :player_id, player_id)}

      {:error, _reason} ->
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     GameServerWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket) do
    nil
  end
end
