defmodule App do
  @moduledoc """
  LaFonciere. What a person sees of it is what it answers; what Constat witnesses of it is the
  check report its CI publishes.

  `App.Supervisor` starts the service, `App.Service` is the service, and `mix serve` is how a
  person runs it. Everything else in here is the name it answers with.
  """

  @doc """
  The product's own name. Changing this was the first witnessed change: it used to read
  "A new service", which is what the template calls a service nobody has named yet.
  """
  def product_name, do: "LaFonciere"
end
