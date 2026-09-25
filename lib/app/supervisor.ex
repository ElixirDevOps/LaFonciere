defmodule App.Supervisor do
  @moduledoc """
  The service's supervision tree. One child for now, restarted on its own if it ever goes down,
  which is what makes starting the service a service rather than a function call.
  """
  use Supervisor

  @children [App.Service]

  @doc "Starts the tree. Registered under its own module name unless told otherwise."
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "The ids of the children this tree is meant to run."
  def children, do: @children

  @doc "The ids of the children it has up right now."
  def children_up(supervisor \\ __MODULE__) do
    for {id, pid, _type, _modules} <- Supervisor.which_children(supervisor), is_pid(pid), do: id
  end

  @doc "Whether it has at least as many children up as it is meant to run."
  def complete?(supervisor \\ __MODULE__) do
    length(children_up(supervisor)) >= length(children())
  end

  @doc "Whether the children it has up are exactly the children it is meant to run."
  def healthy?(supervisor \\ __MODULE__) do
    complete?(supervisor) and Enum.sort(children_up(supervisor)) == Enum.sort(children())
  end

  @impl true
  def init(:ok), do: Supervisor.init(@children, strategy: :one_for_one)
end
