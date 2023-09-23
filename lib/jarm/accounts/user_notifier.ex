defmodule Jarm.Accounts.UserNotifier do
  use JarmWeb, :verified_routes
  import Bamboo.Email

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, subject, body_txt, body_html \\ "") do
    new_email(
      to: to,
      from: {"Jarm", System.fetch_env!("SMTP_USERNAME")},
      subject: subject,
      text_body: body_txt,
      html_body: body_html
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
    email_txt =
      prepare_new_posts(new_posts) <>
        prepare_posts_with_new_comments(your_posts_with_new_comments) <>
        prepare_posts_commented_on_with_new_comments(posts_with_new_comments_where_you_commented)

    email_html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <style>
    html {
      font-family: sans-serif;
    }
    </style>
    </head>
    <body>
    #{prepare_new_posts_html(new_posts)}
    #{prepare_posts_with_new_comments_html(new_posts)}
    #{prepare_posts_commented_on_with_new_comments_html(new_posts)}
    </body>
    </html>
    """

    deliver(user.email, "New posts and comments on Jarm", email_txt, email_html)
  end

  defp prepare_new_posts_html([]), do: ""

  defp prepare_new_posts_html(new_posts) do
    posts =
      List.foldl(new_posts, "", fn p, accumulator ->
        route = get_url_without_port() <> get_post_url(p)

        text = """
        <p><a href="#{route}">#{route}</a><p>
        #{Phoenix.HTML.Format.text_to_html(p.body) |> Phoenix.HTML.safe_to_string()}
        <hr>
        """

        accumulator <> text
      end)

    """
    <h2>New posts</h2>

    #{posts}

    """
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

  defp prepare_posts_with_new_comments_html([]), do: ""

  defp prepare_posts_with_new_comments_html(your_posts_with_new_comments) do
    posts_with_new_comments =
      Enum.map(your_posts_with_new_comments, fn p ->
        get_url_without_port() <> get_post_url(p)
      end)
      |> Enum.reduce("", fn p_url, accumulator ->
        """
        #{accumulator}
        <li><a href="#{p_url}">#{p_url}</a></li>
        """
      end)

    """
    <h2>Your posts with new comments</h2>
    <ul>
    #{posts_with_new_comments}
    </ul>

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

  defp prepare_posts_commented_on_with_new_comments_html([]), do: ""

  defp prepare_posts_commented_on_with_new_comments_html(
         posts_with_new_comments_where_you_commented
       ) do
    new_comments =
      Enum.map(posts_with_new_comments_where_you_commented, fn p ->
        get_url_without_port() <> get_post_url(p)
      end)
      |> Enum.reduce("", fn p_url, accumulator ->
        """
        #{accumulator}
        <li><a href="#{p_url}">#{p_url}</a></li>
        """
      end)

    """
    <h2>Posts you commented on that have new comments</h2>
    <ul>
    #{new_comments}
    </ul>

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
      ~p"/en/posts/#{post.id}",
      "/en/",
      "/"
    )
  end

  defp get_url_without_port() do
    full_url = JarmWeb.Endpoint.struct_url()

    "#{full_url.scheme}://#{full_url.host}"
  end
end
