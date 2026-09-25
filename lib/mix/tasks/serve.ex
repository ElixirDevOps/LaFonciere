defmodule Mix.Tasks.Serve do
  @shortdoc "Starts the service and keeps it up"
  @moduledoc """
  Runs the service.

      $ mix serve
      LaFonciere is running.

  Starts `App.Supervisor`, prints what the started service answers with, and then stays up
  until it is stopped. This is what the Dockerfile runs.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    {:ok, _pid} = App.Supervisor.start_link()
    announce()
    Process.sleep(:infinity)
  end

  @doc """
  Prints what the running service answers with. Split out from `run/1` so the check that takes
  the picture prints it through this same function, rather than retyping the line and hoping it
  still matches.
  """
  def announce, do: IO.puts(App.Service.answer())
end
