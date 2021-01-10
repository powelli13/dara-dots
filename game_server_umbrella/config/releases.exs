import Config

config :game_server_web, GameServerWeb.Endpoint,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
