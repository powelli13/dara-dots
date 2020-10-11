defmodule GameServerWeb.LobbyController do
  use GameServerWeb, :controller

  def index(conn, params) do
    unless params["id"] do
      redirect_invalid_lobby_id(conn)
    end

    # Ensure that they are trying to join a valid lobby that has been created
    case Registry.lookup(GameServer.Registry, {GameServer.LipSyncQueue, params["id"]}) do
      [] ->
        redirect_invalid_lobby_id(conn)

      # If the Registry isn't empty then the Lip Sync queue has been started
      _ ->
        nil
    end

    render(conn, "index.html")
  end

  defp redirect_invalid_lobby_id(conn) do
    conn
    |> put_flash(:info, "Invalid Lip Sync Share Code")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  @doc """
  Creates a new LipSync lobby after generating a new
  share key and then redirects to the new lobby.
  """
  # TODO set the creators name to admin
  def create(conn, _params) do
    id = UUID.uuid4() |> String.split("-") |> hd

    # Start the LipSync queue so that it will be available
    # via the Registry inside of the LobbyChannel
    _ = GameServer.LipSyncQueueSupervisor.find_queue(id)

    redirect(conn, to: "/lobby/#{id}")
  end
end
