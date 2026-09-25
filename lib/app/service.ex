defmodule App.Service do
  @moduledoc """
  The service itself: a process that knows the product's name and answers with it.

  It reads `App.product_name/0` once, when it starts, and holds it as its state — so what a
  running service answers is what it was started with, and asking it is asking the running
  thing rather than re-reading the source behind its back.
  """
  use GenServer

  @doc "Starts the service. Registered under its own module name unless told otherwise."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, App.product_name(), Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "The name the running service holds."
  def name(server \\ __MODULE__), do: GenServer.call(server, :name)

  @doc """
  What the service answers with. This is the one line `mix serve` prints, and the one line the
  check `foundation > answers with its name` takes a picture of.
  """
  def answer(server \\ __MODULE__), do: "#{name(server)} is running."

  @impl true
  def init(product_name), do: {:ok, product_name}

  @impl true
  def handle_call(:name, _from, product_name), do: {:reply, product_name, product_name}
end
