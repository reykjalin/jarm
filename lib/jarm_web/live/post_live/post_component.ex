defmodule JarmWeb.PostLive.PostComponent do
  use JarmWeb, :live_component

  alias JarmWeb.LiveComponents.ReactionsLive

  import Canada, only: [can?: 2]
end
