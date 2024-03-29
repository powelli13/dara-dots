defmodule GameServerWeb.LobbyController do
  use GameServerWeb, :controller

  @system_admin_name "Administrator Alligator"
  @animal_names ["Aardvark", "Bat", "Cougar", "Dalmatian", "Elephant", "Fox", "Gorilla"]

  # Handles requests to join an existing lobby
  def index(conn, params) do
    unless params["lobby_id"] do
      redirect_invalid_lobby_id(conn)
    end

    # Ensure that they are trying to join a valid lobby that has been created
    case Registry.lookup(GameServer.Registry, {GameServer.LipSyncQueue, params["lobby_id"]}) do
      [] ->
        redirect_invalid_lobby_id(conn)

      # If the Registry isn't empty then the Lip Sync queue has been started
      _ ->
        nil
    end

    render(conn, "index.html", player_name: validate_username(params))
  end

  def landing(conn, _params) do
    render(conn, "landing.html")
  end

  # Validates the user name param
  # Returns a random animal name if a valid username was not provided
  defp validate_username(params) do
    # Only allow alphanumeric characters and whitespace for usernames
    # max length of fifty
    cond do
      legal_username?(params["player_name"]) ->
        params["player_name"]

      true ->
        Enum.random(@animal_names)
    end
  end

  defp legal_username?(name) do
    name &&
      Regex.match?(~r/^[A-Za-z0-9\s]{1,50}$/, name) &&
      name != @system_admin_name
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
  def create(conn, params) do
    id =
      UUID.uuid4()
      |> String.split("-")
      |> hd

    # Start the LipSync queue so that it will be available
    # via the Registry inside of the LobbyChannel
    _ = GameServer.LipSyncQueueSupervisor.start_queue(id)

    redirect(conn, to: "/lobby/#{id}?player_name=#{validate_username(params)}")
  end

  @doc """
  Registers a team for the Lip Sync queue.
  """
  def register(conn, params) do
    # Validate form inputs
    case validate_registration(params) do
      {:invalid_lobby_id, _} ->
        redirect_invalid_lobby_id(conn)

      {:error, error_message} ->
        conn
        |> put_flash(:error, error_message)
        |> redirect(to: "/lobby/#{params["lobby_id"]}")

      # If validate_registration returns ok
      # then we know that params hold lobby_id and team_name
      {:ok, video_id} ->
        [{queue_pid, _}] =
          Registry.lookup(
            GameServer.Registry,
            {GameServer.LipSyncQueue, params["lobby_id"]}
          )

        GameServer.LipSyncQueue.add_team(
          queue_pid,
          params["team_name"],
          video_id
        )

        conn
        |> put_flash(:info, "Successfully registered team #{params["team_name"]}.")
        |> redirect(to: "/lobby/#{params["lobby_id"]}")
    end
  end

  # Performs validation on the attempted registration
  # returns a tuple indicating either an error state
  # or that it is valid and should proceed.
  defp validate_registration(params) do
    cond do
      !params["lobby_id"] ->
        {:invalid_lobby_id, ""}

      # TODO determine if team name is already taken?
      # could just append 1 on queue side
      !params["team_name"] ->
        {:error, "Team name is required."}

      !params["video_url"] ->
        {:error, "Video Url is required."}

      # Retrieve the youtube video ID from the submitted URL
      url_captures =
          ~r{^.*(?:youtu\.be/|youtube\.com/watch\?/v=|v=)(?<id>[^#&?]*)}
          |> Regex.named_captures(params["video_url"]) ->
        {:ok, url_captures["id"]}

      # Assume invalid URL id if the above Regex failed
      true ->
        {:error, "Invalid Video Url, must be a YouTube video."}
    end
  end
end
