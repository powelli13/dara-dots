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

  @doc """
  Registers a team for the Lip Sync queue.
  """
  def register(conn, params) do
    # Validate form inputs
    # TODO using an Ecto changeset here could improve things
    valid = true

    unless params["lobby_id"] do
      redirect_invalid_lobby_id(conn)
      valid = false
    end

    # TODO determine if team name is already taken?
    # could just append 1 on queue side
    unless params["team_name"] do
      conn
      |> put_flash(:error, "Team name is required.")
      |> redirect(to: "/lobby/#{params["lobby_id"]}")
      valid = false
    end

    unless params["video_url"] do
      conn
      |> put_flash(:error, "Video Url is required.")
      |> redirect(to: "/lobby/#{params["lobby_id"]}")
      valid = false
    end

    # Retrieve the youtube video ID from the submitted URL
    url_captures =
      ~r{^.*(?:youtu\.be/|youtube\.com/watch\?/v=|v=)(?<id>[^#&?]*)}
      |> Regex.named_captures(params["video_url"])
    
    # Ensure that a video id was found from a YouTube url
    unless url_captures do
      conn
      |> put_flash(:error, "Invalid Video Url, must be a YouTube video.")
      |> redirect(to: "/lobby/#{params["lobby_id"]}")
      valid = false
    end

    if valid do
      [{queue_pid, _}] =
        Registry.lookup(
          GameServer.Registry,
          {GameServer.LipSyncQueue, params["lobby_id"]}
        )

      GameServer.LipSyncQueue.add_team(
        queue_pid,
        params["team_name"],
        url_captures["id"]
      )

      conn
      |> put_flash(:info, "Successfully registered team #{params["team_name"]}.")
      |> redirect(to: "/lobby/#{params["lobby_id"]}")
    end
  end
end
