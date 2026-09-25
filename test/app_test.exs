defmodule AppTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  describe "foundation" do
    test "installs and tests" do
      config = Mix.Project.config()

      # What a fresh checkout has to agree on before anything else can happen.
      assert config[:app] == :app
      assert config[:version] =~ ~r/^\d+\.\d+\.\d+$/
      assert Version.match?(System.version(), config[:elixir])

      # Nothing to fetch, so `mix deps.get` on a fresh checkout cannot fail for want of a
      # network, a private registry, or a lock file this repository does not carry.
      assert config[:deps] == []

      # What it installed is runnable: the service has an entry point of its own.
      assert Mix.Task.get("serve")

      # Running the tests publishes what ran — Constat reads that report, not the console.
      assert Constat.CheckReportFormatter in ExUnit.configuration()[:formatters]

      # ...and CI is the one doing all of it, on a checkout as fresh as this describes.
      workflow = File.read!(".github/workflows/constat-ci.yml")
      assert workflow =~ "actions/checkout@v4"
      assert workflow =~ "mix deps.get"
      assert workflow =~ "mix test"
      assert workflow =~ ".constat/check-report/checks.json"
    end

    test "answers with its name" do
      # The name is the one this repository was given, not the one the template shipped.
      assert App.product_name() == "LaFonciere"

      # The service starts, and the started service is what answers.
      start_supervised!(App.Supervisor)
      assert App.Service.name() == App.product_name()

      answer = App.Service.answer()
      assert answer =~ App.product_name()

      # The picture of what a person sees: the command they type, and the line `mix serve`
      # prints back at them, captured from the same task that prints it. It is written on every
      # run and committed alongside this check, because this repository's CI workflow cannot be
      # taught to publish it as an artifact — the runner's token is refused on any push touching
      # .github/workflows — so the branch itself is where the picture has to live.
      transcript = capture_io(fn -> Mix.Tasks.Serve.announce() end)
      assert transcript =~ answer

      lines = ["$ mix serve" | transcript |> String.trim_trailing() |> String.split("\n")]
      path = Constat.Picture.write!("foundation > answers with its name", lines)

      assert path == ".constat/pictures/foundation-answers-with-its-name.png"
      assert File.exists?(path)
    end
  end
end
