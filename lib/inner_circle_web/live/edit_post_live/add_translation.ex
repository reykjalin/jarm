defmodule InnerCircleWeb.EditPostLive.AddTranslation do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline
  alias InnerCircle.Timeline.Translation

  @impl true
  def mount(params, session, socket) do
    socket = assign_current_user(socket, session)
    socket = assign(socket, :page_title, gettext("Translate jarm"))

    post = Timeline.get_post!(params["id"])
    socket = assign(socket, :post, post)

    changeset = Translation.changeset(%Translation{}, %{})

    {:ok,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"translation" => translation_params}, socket) do
    changeset =
      %Translation{}
      |> Translation.changeset(translation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"translation" => translation_params}, socket) do
    post = socket.assigns.post
    current_user = socket.assigns.current_user

    case Timeline.create_translation(current_user, post, translation_params) do
      {:ok, _translation} ->
        socket
        |> put_flash(:info, gettext("Translation created successfully"))
        |> push_redirect(to: Routes.post_index_path(socket, :index, socket.assigns.locale))

      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, :changeset, changeset)
    end

    {:noreply, socket}
  end
end
