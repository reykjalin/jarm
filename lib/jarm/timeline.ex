defmodule Jarm.Timeline do
  @moduledoc """
  The Timeline context.
  """

  import Ecto.Query, warn: false
  alias Jarm.Timeline.Translation
  alias Jarm.Repo

  use Nebulex.Caching
  alias Jarm.Cache

  alias Jarm.Accounts.User
  alias Jarm.Timeline.Post
  alias Jarm.Timeline.Media
  alias Jarm.Timeline.Comment

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(number \\ 10) do
    Repo.all(from p in Post, order_by: [desc: :inserted_at, desc: :id], limit: ^number)
    |> Repo.preload(:user)
    |> Repo.preload(:media)
    |> Repo.preload(comments: [:user])
    |> Repo.preload(translations: [:user])
  end

  @decorate cacheable(cache: Cache, key: {Post, post.id})
  def list_posts_older_than(%Post{} = post, number \\ 10) do
    from(p in Post,
      where: p.inserted_at < ^post.inserted_at,
      order_by: [desc: :inserted_at, desc: :id],
      limit: ^number
    )
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:media)
    |> Repo.preload(comments: [:user])
    |> Repo.preload(:translations)
  end

  def list_posts_from_yesterday_not_made_by_user(%User{id: id}) do
    today = get_start_of_today()
    yesterday = get_start_of_yesterday()

    from(p in Post,
      where:
        p.user_id != ^id and p.inserted_at >= ^yesterday and
          p.inserted_at <
            ^today
    )
    |> Repo.all()
  end

  def list_posts_with_new_comments_that_user_commented_on(%User{id: id}) do
    today = get_start_of_today()
    yesterday = get_start_of_yesterday()

    posts_user_commented_on = from c in Comment, where: c.user_id == ^id, select: c.post_id

    from(p in Post,
      join: c in Comment,
      on: c.post_id == p.id,
      where:
        p.id in subquery(posts_user_commented_on) and c.user_id != ^id and
          c.inserted_at >= ^yesterday and c.inserted_at < ^today
    )
    |> Repo.all()
  end

  def list_posts_made_by_user_with_new_comments(%User{id: id}) do
    today = get_start_of_today()
    yesterday = get_start_of_yesterday()

    from(p in Post,
      join: c in Comment,
      on: c.post_id == p.id,
      where:
        p.user_id == ^id and c.user_id != ^id and c.inserted_at >= ^yesterday and
          c.inserted_at < ^today
    )
    |> Repo.all()
  end

  def count_posts() do
    Repo.aggregate(Post, :count, :id)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id),
    do:
      Repo.get!(Post, id)
      |> Repo.preload(:user)
      |> Repo.preload(:media)
      |> Repo.preload(comments: [:user])
      |> Repo.preload(:translations)

  @decorate cacheable(cache: Cache, key: uuid)
  def get_media(uuid) do
    from(m in Media, where: m.uuid == ^uuid) |> Repo.one()
  rescue
    Ecto.Query.CastError -> nil
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(current_user, attrs \\ %{}) do
    # We don't broadcast creations.
    # TODO: broadcast creation to trigger a "show newer posts" link.
    %Post{user_id: current_user.id}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def create_media(%User{id: user_id}, %Post{id: post_id}, attrs \\ %{}) do
    %Media{user_id: user_id, post_id: post_id}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  @decorate cache_evict(cache: Cache, key: {Post, post_id})
  def create_comment(%User{id: user_id}, %Post{id: post_id}, attrs \\ %{}) do
    %Comment{post_id: post_id, user_id: user_id}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:comment_created)
  end

  @decorate cache_evict(cache: Cache, key: {Post, post_id})
  def create_translation(%User{id: user_id}, %Post{id: post_id}, attrs \\ %{}) do
    %Translation{post_id: post_id, user_id: user_id}
    |> Translation.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:translation_created)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> broadcast(:post_updated)
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
    |> broadcast(:post_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Jarm.PubSub, "posts")
    Phoenix.PubSub.subscribe(Jarm.PubSub, "comments")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, post}, :post_deleted) do
    Phoenix.PubSub.broadcast(Jarm.PubSub, "posts", {:post_deleted, post})
    {:ok, post}
  end

  defp broadcast({:ok, post}, :post_updated) do
    # We need to re-fetch the user to make sure user information is loaded.
    post = get_post!(post.id)
    Phoenix.PubSub.broadcast(Jarm.PubSub, "posts", {:post_updated, post})
    {:ok, post}
  end

  defp broadcast({:ok, comment}, :comment_created) do
    Phoenix.PubSub.broadcast(Jarm.PubSub, "comments", {:comment_created, comment})
    {:ok, comment}
  end

  defp broadcast({:ok, translation}, :translation_created) do
    Phoenix.PubSub.broadcast(
      Jarm.PubSub,
      "translations",
      {:translation_created, translation}
    )

    {:ok, translation}
  end

  defp get_start_of_today() do
    today_precise = NaiveDateTime.utc_now()
    NaiveDateTime.new!(today_precise.year, today_precise.month, today_precise.day, 0, 0, 0)
  end

  defp get_start_of_yesterday() do
    # 24 hr/day * 60 min/hr * 60 sec/min = 86_400 seconds.
    one_day_in_seconds = 172_800
    today_precise = NaiveDateTime.utc_now()
    yesterday_precise = NaiveDateTime.add(today_precise, -one_day_in_seconds, :second)

    NaiveDateTime.new!(
      yesterday_precise.year,
      yesterday_precise.month,
      yesterday_precise.day,
      0,
      0,
      0
    )
  end
end
