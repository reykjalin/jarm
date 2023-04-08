defmodule InnerCircle.Accounts.UserNotifier do
  import Bamboo.Email

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, subject, body) do
    new_email(
      to: to,
      from: {"Inner Circle", System.fetch_env!("SMTP_USERNAME")},
      subject: subject,
      text_body: body,
      html_body: nil
    )
    |> InnerCircle.Mailer.deliver_later()
  end

  @doc """
  Deliver instructions to the provided email so the recipient can create an account.
  """
  def deliver_invitation(email, url) do
    deliver(email, "You've been invited to join Inner Circle!", """
    Hi #{email},

    You've been invited to Inner Circle.

    You can create your account by visiting the URL below:

    #{url}

    If you weren't expecting this invitation, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset Password request on Inner Circle", """
    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Email change request on Inner Circle", """
    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end

  def deliver_notification(_user, [], [], []) do
    :ok
  end

  @doc """
  Delivers notifications to the specified user based on the list of posts and comments.
  """
  def deliver_notification(
        user,
        new_posts,
        your_posts_with_new_comments,
        posts_with_new_comments_where_you_commented
      ) do
    email =
      prepare_new_posts(new_posts) <>
        prepare_posts_with_new_comments(your_posts_with_new_comments) <>
        prepare_posts_commented_on_with_new_comments(posts_with_new_comments_where_you_commented)

    deliver(user.email, "New posts and comments on Inner Circle", email)
  end

  defp prepare_new_posts([]), do: ""

  defp prepare_new_posts(new_posts) do
    posts =
      List.foldl(new_posts, "", fn p, accumulator ->
        route =
          InnerCircleWeb.Endpoint.url() <>
            String.replace(
              InnerCircleWeb.Router.Helpers.post_show_path(
                InnerCircleWeb.Endpoint,
                :show,
                "en",
                p.id
              ),
              "/en/",
              "/"
            )

        text = """
        URL: #{route}

        #{p.body}

        ---
        """

        accumulator <> text
      end)

    """
    New posts
    =========

    #{posts}

    """
  end

  defp prepare_posts_with_new_comments([]), do: ""

  defp prepare_posts_with_new_comments(your_posts_with_new_comments) do
    posts_with_new_comments =
      Enum.map(your_posts_with_new_comments, fn p ->
        InnerCircleWeb.Endpoint.url() <>
          String.replace(
            InnerCircleWeb.Router.Helpers.post_show_path(
              InnerCircleWeb.Endpoint,
              :show,
              "en",
              p.id
            ),
            "/en/",
            "/"
          )
      end)
      |> Enum.uniq()
      |> Enum.reduce("", fn p_url, accumulator ->
        """
        #{accumulator}
        #{p_url}
        """
      end)

    """
    Your posts with new comments
    ============================
    #{posts_with_new_comments}

    """
  end

  defp prepare_posts_commented_on_with_new_comments([]), do: ""

  defp prepare_posts_commented_on_with_new_comments(posts_with_new_comments_where_you_commented) do
    new_comments =
      Enum.map(posts_with_new_comments_where_you_commented, fn p ->
        InnerCircleWeb.Endpoint.url() <>
          String.replace(
            InnerCircleWeb.Router.Helpers.post_show_path(
              InnerCircleWeb.Endpoint,
              :show,
              "en",
              p.id
            ),
            "/en/",
            "/"
          )
      end)
      |> Enum.uniq()
      |> Enum.reduce("", fn p_url, accumulator ->
        """
        #{accumulator}
        #{p_url}
        """
      end)

    """
    Posts you commented on that have new comments
    =============================================
    #{new_comments}

    """
  end
end
