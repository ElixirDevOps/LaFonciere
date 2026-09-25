defmodule App.Supervisor do
  @moduledoc """
  The service's supervision tree. One child for now — the service — restarted on its own if it
  ever goes down, which is what makes starting it a service rather than a function call.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok), do: Supervisor.init([App.Service], strategy: :one_for_one)
end
