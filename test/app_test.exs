defmodule AppTest do
  use ExUnit.Case, async: true

  describe "foundation" do
    test "installs and tests" do
      assert function_exported?(App, :product_name, 0)
    end

    test "answers with its name" do
      assert String.length(App.product_name()) > 0
    end
  end
end
