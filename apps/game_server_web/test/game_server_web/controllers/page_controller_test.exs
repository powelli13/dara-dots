defmodule GameServerWeb.PageControllerTest do
  use GameServerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Games and Lip Sync!"
  end
end
