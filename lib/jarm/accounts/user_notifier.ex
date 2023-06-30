defmodule Jarm.Accounts.UserNotifier do
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
      from: {"Jarm", System.fetch_env!("SMTP_USERNAME")},
      subject: subject,
      text_body: body,
      html_body: nil
    )
    |> Jarm.Mailer.deliver_later()
  end

  @doc """
  Deliver instructions to the provided email so the recipient can create an account.
  """
  def deliver_invitation(email, url) do
    deliver(email, "You've been invited to join Jarm!", """
    Hi #{email},

    You've been invited to Jarm.

    You can create your account by visiting the URL below:

    #{url}

    If you weren't expecting this invitation, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset Password request on Jarm", """
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
    deliver(user.email, "Email change request on Jarm", """
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

    deliver(user.email, "New posts and comments on Jarm", email)
  end

  defp prepare_new_posts([]), do: ""

  defp prepare_new_posts(new_posts) do
    posts =
      List.foldl(new_posts, "", fn p, accumulator ->
        route = get_url_without_port() <> get_post_url(p)

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
        get_url_without_port() <> get_post_url(p)
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
        get_url_without_port() <> get_post_url(p)
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

  defp get_post_url(post) do
    String.replace(
      JarmWeb.Router.Helpers.post_show_path(
        JarmWeb.Endpoint,
        :show,
        "en",
        post.id
      ),
      "/en/",
      "/"
    )
  end

  defp get_url_without_port() do
    full_url = JarmWeb.Endpoint.struct_url()

    "#{full_url.scheme}://#{full_url.host}"
  end
end
