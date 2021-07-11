defmodule InnerCircleWeb.PostLive.FormComponent do
  use InnerCircleWeb, :live_component

  alias InnerCircle.Timeline

  import Canada, only: [can?: 2]

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Timeline.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Timeline.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    post = socket.assigns.post
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(edit(post)) do
        true ->
          case Timeline.update_post(socket.assigns.post, post_params) do
            {:ok, _post} ->
              socket
              |> put_flash(:info, "Post updated successfully")
              |> push_redirect(to: socket.assigns.return_to)

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, :changeset, changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to modify this post")
          |> push_redirect(to: socket.assigns.return_to)
      end

    {:noreply, socket}
  end

  defp save_post(socket, :new, post_params) do
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(create(InnerCircle.Timeline.Post)) do
        true ->
          case Timeline.create_post(socket.assigns.current_user, post_params) do
            {:ok, _post} ->
              socket
              |> put_flash(:info, "Post created successfully")
              |> push_redirect(to: socket.assigns.return_to)

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, changeset: changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to create new posts")
          |> push_redirect(to: socket.assigns.return_to)
      end

    {:noreply, socket}
  end
end
