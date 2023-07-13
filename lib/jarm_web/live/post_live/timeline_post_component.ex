defmodule JarmWeb.PostLive.TimelinePostComponent do
  use JarmWeb, :live_component

  alias Phoenix.LiveView.JS

  import Canada, only: [can?: 2]
end
