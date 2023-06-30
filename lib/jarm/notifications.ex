defmodule Jarm.Notifications do
  alias Jarm.Accounts
  alias Jarm.Timeline

  def send_notifications() do
    Accounts.get_all_users()
    |> Enum.each(fn u ->
      new_posts = Timeline.list_posts_from_yesterday_not_made_by_user(u)
      your_posts_with_new_comments = Timeline.list_posts_made_by_user_with_new_comments(u)

      posts_you_commented_on_with_new_comments =
        Timeline.list_posts_with_new_comments_that_user_commented_on(u)

      Accounts.UserNotifier.deliver_notification(
        u,
        new_posts,
        your_posts_with_new_comments,
        posts_you_commented_on_with_new_comments
      )
    end)
  end
end
