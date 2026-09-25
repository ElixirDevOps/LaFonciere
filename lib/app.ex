defmodule App do
  @moduledoc """
  LaFonciere.

  What a person sees of it is what it answers. What Constat witnesses of it is the check report
  its CI publishes.

  `App.Supervisor` starts the service. `App.Service` is the service. `mix serve` is how a person
  runs it. Everything else here is the name it answers with.
  """

  # The name this repository chose. Changing it from the placeholder below was the first
  # witnessed change this repository made, which is the whole of what "Lay the foundation" asks
  # for, and why the service refuses to start while the placeholder is still in force.
  @product_name "LaFonciere"

  # What the template calls a service nobody has named yet.
  @template_name "A new service"

  @doc "The product's own name."
  def product_name, do: @product_name

  @doc "Whether `name` is the placeholder the template ships every new service under."
  def template_name?(name), do: name == @template_name

  @doc "Whether the product carries a name somebody chose."
  def named?, do: not template_name?(product_name())
end
