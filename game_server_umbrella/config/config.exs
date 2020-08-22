# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :game_server,
  ecto_repos: [GameServer.Repo]

config :game_server_web,
  ecto_repos: [GameServer.Repo],
  generators: [context_app: :game_server]

# Configures the endpoint
config :game_server_web, GameServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zStiB/ks4GLBfAJK8DQrEYtN8VQJ+u9LquzXtkn1v8RmiOhbtscv5OtjlqH6XM/A",
  render_errors: [view: GameServerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GameServer.PubSub,
  live_view: [signing_salt: "DyZzG3MZ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
