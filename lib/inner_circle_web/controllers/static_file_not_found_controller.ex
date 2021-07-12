defmodule InnerCircleWeb.StaticFileNotFoundController do
  use InnerCircleWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(404)
    |> text("File not found")
  end
end
