defmodule JarmWeb.PostLive.TimelinePostComponent do
  use JarmWeb, :live_component

  alias JarmWeb.LiveComponents.ReactionsLive

  import Canada, only: [can?: 2]
end
