defmodule Jarm.Notifications do
  import Ecto.Query, warn: false

  alias Jarm.Accounts
  alias Jarm.Timeline
  alias Jarm.Repo

  def send_notifications() do
    # We get the posts and comments that should trigger notifications.
    posts =
      Timeline.list_posts_that_have_not_triggered_a_notification()

    comments =
      Timeline.list_comments_that_have_not_triggered_a_notification()

    Accounts.get_all_users()
    |> Enum.each(fn u ->
      others_comment_post_ids =
        comments |> get_comments_not_made_by_user(u) |> Enum.map(fn c -> c.post_id end)

      your_comment_post_ids =
        comments |> get_comments_made_by_user(u) |> Enum.map(fn c -> c.post_id end)

      # Posts that you did not make.
      new_posts = posts |> get_posts_not_made_by_user(u)
      # Posts that were (a) made by you and (b) others commented on.
      your_posts_with_new_comments =
        posts
        |> get_posts_made_by_user(u)
        |> Enum.filter(fn p -> p.id in others_comment_post_ids end)

      # Posts where (a) you commented and (b) others commented.
      posts_you_commented_on_with_new_comments =
        posts
        |> Enum.filter(fn p -> p.id in your_comment_post_ids end)
        |> Enum.filter(fn p -> p.id in others_comment_post_ids end)

      # Send notification
      Accounts.UserNotifier.deliver_notification(
        u,
        new_posts,
        your_posts_with_new_comments,
        posts_you_commented_on_with_new_comments
      )
    end)

    enable_sent_notification_flag_for(posts)
    enable_sent_notification_flag_for(comments)
  end

  def enable_sent_notification_flag_for(objects_that_trigger_notifications) do
    post_ids =
      objects_that_trigger_notifications
      |> Enum.map(fn o -> get_post_id(o) end)
      |> Enum.filter(fn id -> id != nil end)

    comment_ids =
      objects_that_trigger_notifications
      |> Enum.map(fn o -> get_comment_id(o) end)
      |> Enum.filter(fn id -> id != nil end)

    if not Enum.empty?(post_ids) do
      from(p in Timeline.Post, where: p.id in ^post_ids)
      |> Repo.update_all(set: [notification_sent: true])
    end

    if not Enum.empty?(comment_ids) do
      from(c in Timeline.Comment, where: c.id in ^comment_ids)
      |> Repo.update_all(set: [notification_sent: true])
    end
  end

  def disable_sent_notification_flag_for(objects_that_trigger_notifications) do
    post_ids =
      objects_that_trigger_notifications
      |> Enum.map(fn o -> get_post_id(o) end)
      |> Enum.filter(fn id -> id != nil end)

    comment_ids =
      objects_that_trigger_notifications
      |> Enum.map(fn o -> get_comment_id(o) end)
      |> Enum.filter(fn id -> id != nil end)

    if not Enum.empty?(post_ids) do
      from(p in Timeline.Post, where: p.id in ^post_ids)
      |> Repo.update_all(set: [notification_sent: false])
    end

    if not Enum.empty?(comment_ids) do
      from(c in Timeline.Comment, where: c.id in ^comment_ids)
      |> Repo.update_all(set: [notification_sent: false])
    end
  end

  defp get_posts_not_made_by_user(posts, %Accounts.User{id: user_id}) do
    posts
    |> Enum.filter(fn p -> p.user_id != user_id end)
  end

  defp get_posts_made_by_user(posts, %Accounts.User{id: user_id}) do
    posts
    |> Enum.filter(fn p -> p.user_id == user_id end)
  end

  defp get_comments_not_made_by_user(comments, %Accounts.User{id: user_id}) do
    comments
    |> Enum.filter(fn c -> c.user_id != user_id end)
  end

  defp get_comments_made_by_user(comments, %Accounts.User{id: user_id}) do
    comments
    |> Enum.filter(fn c -> c.user_id == user_id end)
  end

  defp get_post_id(%Timeline.Post{id: id}), do: id
  defp get_post_id(_), do: nil

  defp get_comment_id(%Timeline.Comment{id: id}), do: id
  defp get_comment_id(_), do: nil
end
