defmodule GameServerWeb.LobbyController do
  use GameServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  Creates a new LipSync lobby after generating a new
  share key and then redirects to the new lobby.
  """
  # TODO set the creators name to admin
  def create(conn, _params) do
    id = UUID.uuid4 |> String.split("-") |> hd

    redirect(conn, to: "/lobby/#{id}")
  end
end
