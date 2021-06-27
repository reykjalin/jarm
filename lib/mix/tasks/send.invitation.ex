defmodule Mix.Tasks.Send.Invitation do
  use Mix.Task

  alias InnerCircle.Accounts

  @shortdoc "Send an invitation that will allow someone to join Inner Circle"

  @moduledoc """
  Usage: mix send.invitation <email>

  Creates an invitation that will be sent to the provided email.
  """

  def run(args) do
    Mix.Task.run("app.start")

    url_func = &"/users/register/#{&1}"
    email = Enum.at(args, 0, "")

    Accounts.deliver_user_invitation(email, url_func)
  end
end
