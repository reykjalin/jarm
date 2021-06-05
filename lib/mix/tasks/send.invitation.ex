defmodule Mix.Tasks.Send.Invitation do
	use Mix.Task

	@shortdoc "Send an invitation to create an account on Inner Circle"

	@moduledoc """
	Docs Docs Docs...
	"""

	def run(_args) do
		Mix.Task.run("app.start")
		Mix.shell().info("Greetings!")
	end
end
