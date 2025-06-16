defmodule AshTypescript.MixProject do
  use Mix.Project

  @version "0.1.0"

  @description """
  The extension for tracking changes to your resources via a centralized event log, with replay functionality.
  """

  def project do
    [
      app: :ash_typescript,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      consolidate_protocols: Mix.env() == :prod,
      docs: &docs/0,
      description: @description,
      source_url: "https://github.com/ash-project/ash_typescript",
      homepage_url: "https://github.com/ash-project/ash_typescript",
      preferred_cli_env: [
        "test.codegen": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix]
      ]
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash", override: true]
      "main" -> [git: "https://github.com/ash-project/ash.git"]
      version -> "~> #{version}"
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    application(Mix.env())
  end

  defp application(:test) do
    [
      mod: {AshTypescript.TestApp, []},
      extra_applications: [:logger]
    ]
  end

  defp application(_) do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: :ash_typescript,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README*
        CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_typescript"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extra_section: "GUIDES",
      extras: [
        {"README.md", title: "Home"},
        {"documentation/dsls/DSL-AshTypescript.RPC.md",
         search_data: Spark.Docs.search_data_for(AshTypescript.RPC)},
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Tutorials: ~r'documentation/tutorials',
        "How To": ~r'documentation/how_to',
        Topics: ~r'documentation/topics',
        DSLs: ~r'documentation/dsls',
        "About AshTypescript": [
          "CHANGELOG.md"
        ]
      ],
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <script>
            if (location.hostname === "hexdocs.pm") {
              var script = document.createElement("script");
              script.src = "https://plausible.io/js/script.js";
              script.setAttribute("defer", "defer")
              script.setAttribute("data-domain", "ashhexdocs")
              document.head.appendChild(script);
            }
          </script>
          """
        end
      end
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ash_version("~> 3.5")},
      {:ash_phoenix, "~> 2.0"},
      {:git_ops, "~> 2.0", only: [:dev], runtime: false},
      {:sourceror, "~> 1.7", only: [:dev, :test]},
      {:faker, "~> 0.18", only: :test},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:picosat_elixir, "~> 0.2", only: [:dev, :test]},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "test.codegen": "ash_typescript.codegen",
      sobelow: "sobelow --skip",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
      credo: "credo --strict",
      "spark.formatter": "spark.formatter --extensions AshTypescript.RPC",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshTypescript.RPC"
    ]
  end
end
