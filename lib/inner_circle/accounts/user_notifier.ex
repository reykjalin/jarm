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
end
