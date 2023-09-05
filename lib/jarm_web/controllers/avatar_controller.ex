defmodule JarmWeb.AvatarController do
  use JarmWeb, :controller

  import Ecto.Query, warn: false

  alias Jarm.Repo

  def show(conn, %{"user_id" => user_id, "avatar" => avatar}) do
    config =
      from(uc in Jarm.Accounts.UserConfiguration, where: uc.user_id == ^user_id)
      |> Repo.one()

    avatar_path =
      case avatar do
        "email_cat" ->
          config.email_cat_avatar_path

        "name_cat" ->
          config.display_name_cat_avatar_path

        "custom_cat" ->
          config.custom_cat_avatar_path

        _ ->
          ""
      end

    if avatar_path == "" or not File.exists?(avatar_path) do
      conn
      |> put_status(404)
      |> text("File not found")
    else
      conn
      |> Plug.Conn.put_resp_header("content-type", "image/webp")
      |> Plug.Conn.put_resp_header("cache-control", "private,max-age=31536000,immutable")
      |> Plug.Conn.send_file(200, avatar_path)
    end
  end
end
