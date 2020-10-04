defmodule GameServerWeb.LobbyController do
  use GameServerWeb, :controller

  def index(conn, params) do
    # TODO navigate back to the root page
    # if the lobby code doesn't exist
    # I think this means we'll need to register lobbys
    # Valid lobby IDs are required to join
    unless params["id"] do
      conn
      |> put_flash(:info, "Invalid lobby ID")
      |> redirect(to: Routes.page_path(conn, :index))
    end

    render(conn, "index.html")
  end

  @doc """
  Creates a new LipSync lobby after generating a new
  share key and then redirects to the new lobby.
  """
  # TODO set the creators name to admin
  def create(conn, _params) do
    id = UUID.uuid4() |> String.split("-") |> hd

    redirect(conn, to: "/lobby/#{id}")
  end
end
