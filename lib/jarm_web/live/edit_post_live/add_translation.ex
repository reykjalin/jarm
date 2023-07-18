defmodule JarmWeb.EditPostLive.AddTranslation do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Translation

  @impl true
  def mount(params, session, socket) do
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
        {:noreply,
         socket
         |> put_flash(:info, gettext("Translation created successfully"))
         |> push_redirect(to: ~p"/#{socket.assigns.locale}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      _ ->
        {:noreply, socket}
    end
  end
end
