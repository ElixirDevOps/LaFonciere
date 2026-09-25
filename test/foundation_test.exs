defmodule Foundation do
  @moduledoc """
  The foundation checks: one per acceptance criterion, each named word for word after the
  criterion it proves. The per-test report this suite publishes prefixes every name with the
  module, so this module is named for the requirement rather than for the module it happens to
  exercise, which is what makes the published names read
  `Foundation > installs and tests`, `Foundation > answers with its name`, then the readiness
  one.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "installs and tests" do
    config = Mix.Project.config()

    # A fresh checkout has nothing to fetch, so `mix deps.get` on it cannot fail for want of a
    # network, a private registry, or a lock file this repository does not carry.
    assert config[:app] == :app
    assert config[:deps] == []
    assert config[:version] =~ ~r/^\d+\.\d+\.\d+$/
    assert Version.match?(System.version(), config[:elixir])

    # What it installed is runnable: the service has an entry point of its own, and the tree
    # behind that entry point comes up on a checkout with nothing else done to it.
    assert Mix.Task.get("serve") == Mix.Tasks.Serve

    start_supervised!(App.Supervisor)
    assert App.Supervisor.children_up() == [App.Service]
    assert App.Supervisor.complete?()
    assert App.Supervisor.healthy?()
    assert App.Service.running?()

    # Running the tests publishes what ran. Constat reads that report, never the console.
    assert Constat.CheckReportFormatter in ExUnit.configuration()[:formatters]

    # ...and CI is the one doing all of it, on a checkout as fresh as this describes.
    workflow = File.read!(".github/workflows/constat-ci.yml")
    assert workflow =~ "actions/checkout@v4"
    assert workflow =~ "mix deps.get"
    assert workflow =~ "mix test"
    assert workflow =~ ".constat/check-report/checks.json"
  end

  test "answers with its name" do
    # The name is the one this repository chose, never the one the template ships with.
    assert App.product_name() == "LaFonciere"
    assert App.named?()
    assert App.template_name?("A new service")
    refute App.template_name?(App.product_name())

    # The service starts, and the started service is what answers: the name comes back out of
    # the running process, not out of the source behind its back.
    start_supervised!(App.Supervisor)
    assert App.Service.running?()
    assert App.Service.name() == "LaFonciere"
    assert App.Service.own_name?()
    assert App.Service.answer() == "LaFonciere is running."

    # What a person actually sees: the one line `mix serve` prints back at them, captured from
    # the very task that prints it rather than retyped here in the hope it still matches.
    transcript = capture_io(fn -> Mix.Tasks.Serve.announce() end)
    assert transcript == "LaFonciere is running.\n"

    lines = ["$ mix serve" | transcript |> String.trim_trailing() |> String.split("\n")]
    path = Constat.Picture.write!("Foundation > answers with its name", lines)

    assert path == ".constat/pictures/foundation-answers-with-its-name.png"
    assert File.exists?(path)
  end

  test "Constat reads the repository as ready: evidence, runner, and a Run button" do
    ci = File.read!(".github/workflows/constat-ci.yml")
    extra = File.read!(".github/workflows/constat-ci-coverage-mutation.yml")
    runner = File.read!(".github/workflows/constat-runner.yml")

    # Evidence: every artifact Constat's collectors read is published by this repository's own
    # CI, under the name the collector looks for.
    assert ci =~ "name: constat-check-report"
    assert ci =~ ".constat/check-report/checks.json"
    assert ci =~ "name: constat-check-report-base"
    assert extra =~ "name: constat-check-coverage"
    assert extra =~ ".constat/check-coverage/coverage.json"
    assert extra =~ "name: constat-check-report-mutation"
    assert extra =~ ".constat/check-mutation/mutation.json"

    # Runner: the workflow that takes a queued attempt and runs it here, on this repository's
    # own machine, with this repository's own key.
    assert File.exists?(".github/scripts/constat-runner.mjs")
    assert runner =~ "node .github/scripts/constat-runner.mjs"
    assert runner =~ "schedule:"
    assert runner =~ "CLAUDE_CODE_OAUTH_TOKEN"

    # A Run button: workflow_dispatch is what puts one on the page, for the checks as for the
    # runner.
    assert ci =~ "workflow_dispatch"
    assert runner =~ "workflow_dispatch"

    # The picture: the readiness this check just read off the repository, laid out the way a
    # person reads it. It is this repository's own account of itself — Constat's reporter is
    # what turns it into the ready-or-not a person sees in Constat.
    lines = [
      "$ mix test",
      "",
      "repository readiness, as this repository presents it",
      "",
      "  evidence  ci_run     constat-ci          .constat/check-report/checks.json",
      "  evidence  coverage   coverage-mutation   .constat/check-coverage/coverage.json",
      "  evidence  mutation   coverage-mutation   .constat/check-mutation/mutation.json",
      "  runner    attempts   constat-runner      .github/scripts/constat-runner.mjs",
      "  button    Run        workflow_dispatch   constat-ci, constat-runner",
      "",
      "  all three present: evidence, runner, Run button"
    ]

    name = "Foundation > Constat reads the repository as ready: evidence, runner, and a Run button"
    path = Constat.Picture.write!(name, lines)

    assert path ==
             ".constat/pictures/foundation-constat-reads-the-repository-as-ready-evidence-runner-and-a-run-button.png"

    assert File.exists?(path)
  end
end
