defmodule GameServerWeb.Router do
  use GameServerWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {GameServerWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # TODO I think this could be simplified by using resources instead of get post directly 
  scope "/", GameServerWeb do
    pipe_through [:browser, :put_player_token]

    get "/", PageController, :index

    get "/lip-sync-landing", LobbyController, :landing

    get "/lobby", LobbyController, :index

    get "/lobby/:lobby_id", LobbyController, :index

    post "/lobby", LobbyController, :create

    post "/lobby/register", LobbyController, :register

    get "/game", GameController, :index

    get "/rps-game-lobby", GameController, :lobby

    get "/ttt-game", TttGameController, :index

    get "/ttt-game-lobby", TttGameController, :lobby

    get "/pong-game", PongController, :index

    get "/pong-lobby", PongController, :lobby

    live "/lipsynclive", LipSyncLive

    live "/lobbychatlive", LobbyChatLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameServerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GameServerWeb.Telemetry
    end
  end

  # Ensures that each visitor to the site
  # as a Player ID stored in the session, and
  # a token on the assigns for the client
  # to use when connecting to a socket.
  # This Player ID is used later when joining
  # queues and identifying the player.
  defp put_player_token(conn, _) do
    # Ensure that the conn has a player ID
    if player_id = get_session(conn, :player_id) do
      token = Phoenix.Token.sign(conn, "user socket", player_id)
      assign(conn, :player_token, token)
    else
      new_player_id = UUID.uuid4()
      token = Phoenix.Token.sign(conn, "user socket", new_player_id)

      conn
      |> put_session(:player_id, new_player_id)
      |> assign(:player_token, token)
    end
  end
end
