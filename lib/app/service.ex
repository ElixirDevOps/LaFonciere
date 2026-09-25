defmodule App.Service do
  @moduledoc """
  The service: a process that knows the product's name, answering with it.

  It reads `App.product_name/0` once, when it starts, then holds it as its state. So what a
  running service answers is what it was started with: asking it is asking the running thing,
  never re-reading the source behind its back.

  It refuses to start while the product still carries the template's placeholder name. A service
  nobody has named has nothing to answer with, so there is nothing for it to be up for.
  """
  use GenServer

  @doc "Starts the service. Registered under its own module name unless told otherwise."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, App.product_name(), Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "Whether the service is up."
  def running?(server \\ __MODULE__) do
    pid = GenServer.whereis(server)
    pid != nil && Process.alive?(pid)
  end

  @doc "The name the running service holds."
  def name(server \\ __MODULE__), do: GenServer.call(server, :name)

  @doc "Whether the name the running service holds is the product's own."
  def own_name?(server \\ __MODULE__) do
    name(server) == App.product_name()
  end

  @doc """
  What the service answers with. This is the one line `mix serve` prints, the one line the check
  `Foundation > answers with its name` takes a picture of.
  """
  def answer(server \\ __MODULE__) do
    if running?(server) do
      "#{name(server)} is running."
    else
      "#{App.product_name()} is not running."
    end
  end

  @impl true
  def init(product_name) do
    if App.named?() do
      {:ok, product_name}
    else
      {:stop, :unnamed}
    end
  end

  @impl true
  def handle_call(:name, _from, product_name), do: {:reply, product_name, product_name}
end
