defmodule GameServerWeb.Presence do
  use Phoenix.Presence,
    otp_app: :game_server_web,
    pubsub_server: GameServer.PubSub
end
