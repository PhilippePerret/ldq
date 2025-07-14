defmodule LdQ.MixProject do
  use Mix.Project

  def project do
    [
      app: :ldq,
      version: "0.2.43",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]
  end

  def docs do
    [
      output: "doc/mix_doc/",
      main: "LdQ",
      extra_section: "GUIDES",
      api_reference: false,
      extras: ["README.md", "TODO.md", "doc/FONCTIONNEMENT.md", "doc/ARCHITECTURE.md", "doc/TESTS.md", "doc/doc.livemd"],
      groups_for_modules: [
        Comptes: [
          LdQ.Comptes,
          LdQ.Comptes.Getters,
          LdQ.Comptes.Helpers,
          LdQ.Comptes.Membre,
          LdQ.Comptes.MemberCard,
          LdQ.Comptes.User,
          LdQ.Comptes.UserNotifier,
          LdQ.Comptes.UserToken
        ],
        Librairie: [
          LdQ.Library,
          LdQ.Library.Author,
          LdQ.Library.Book,
          LdQ.SubmittedBook,
          LdQ.Library.Publisher,
          LdQ.Library.Genre
        ],
        "Site Web": [
          LdQWeb.Router,
          LdQ.Site,
          LdQWeb.Layouts,
          LdQWeb.Layouts.App,
          LdQ.Site.Page,
          LdQWeb.PageController,
          LdQWeb.PageHTML,
          LdQ.Site.PageHelpers,
          LdQ.Site.PageLocale,
          Site.PageLocale.Locale,
          Site.PageLocale.Status,
          LdQWeb.PageLocaleController,
          LdQWeb.PageLocaleHTML,
          LdQWeb.SpecPageController,
          LdQWeb.SpecPageHTML,
          LdQ.Site.Log,
          LdQWeb.ChantierController,
          LdQWeb.ChantierHTML
        ],
        "Comité": [
          LdQWeb.ComiteController,
          LdQWeb.ComiteHTML,
          LdQWeb.MembreController,
          LdQWeb.MembreHTML
        ],
        "Évaluation": [
          LdQ.Evaluation.Numbers,
          LdQ.Evaluation.UserBook
        ],
        Administration: [
          LdQWeb.AdminController,
          LdQWeb.AdminHTML,
        ],
        "Procédures": [
          LdQ.Procedure,
          LdQ.ProcedureMethods,
          LdQWeb.Procedure,
          LdQWeb.ProcedureController,
          LdQWeb.ProcedureHTML
        ],
        "Cœur": [
          LdQ.Constantes,
          LdQ.Core,
          LdQ.Core.Trigger,
          LdQ.Core.TriggerAbsdata,
          LdQ.Core.TriggerDaemon
        ],
        Communication: [
          LdQ.Notification,
          LdQ.Mailer,
          LdQ.Mailing,
          LdQ.MyMailer,
          LdQ.Mails.Helpers
        ],
        Helpers: [
          LdQWeb.Gettext,
          Html.Helpers,
          Helpers.Feminines,
          LdQ.LinkHelpers,
          LdQ.Mails.Helpers,
          LdQWeb.ViewHelpers,
          Html.Form,
          Html.Form.Field
        ],
        "User actions": [
          LdQWeb.UserSessionController,
          LdQWeb.UserSettingsLive,
          LdQWeb.UserAuth,
          LdQWeb.UserLoginLive,
          LdQWeb.UserConfirmationInstructionsLive,
          LdQWeb.UserConfirmationLive,
          LdQWeb.UserForgotPasswordLive,
          LdQWeb.UserRegistrationLive,
          LdQWeb.UserResetPasswordLive,
          LdQWeb.InscritController,
          LdQWeb.InscritHTML
        ],
        Erreurs: [
          LdQWeb.ErrorHTML,
          LdQWeb.ErrorJSON
        ],
        Tests: [
          LdQ.Tests.Mails
        ],
        Tools: [
          Mix.LdQMethods
        ],
        Divers: [
          Phil,
          Phil.File,
          Phil.Keyword,
          Phil.Map,
          Phil.PFile,
          LdQ.PhilHtml,
          Flag
        ],
        Fonctionnel: [
          LdQWeb,
          LdQ.Release,
          LdQ.Repo,
          LdQWeb.CoreComponents,
          LdQWeb.Endpoint,
          LdQWeb.Telemetry
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LdQ.Application, []},
      extra_applications: [:logger, :runtime_tools],
      # ChatGPT m'a fait ajouter LdQ.Repo ci-dessous pour pouvoir utiliser
      # LdQ.Repo dans les tâches Mix
      # extra_applications: [:logger, :runtime_tools, :ldq],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:wallaby, "~> 0.30.0", only: :test},
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
      {:philhtml, path: "/Users/philippeperret/Programmes/Phoenix/philhtml"},
      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      # {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      # {:phoenix_markdown, "~> 1.0"},
      {:earmark, "~> 1.4"},
      {:swoosh, "~> 1.5"},
      {:gen_smtp, "~> 1.1"}, # chargement explicite
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      # POUR LIVEBOOK
      {:kino, "~> 0.16.0"},
      {:bandit, "~> 1.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind ldq", "esbuild ldq"],
      "assets.deploy": [
        "tailwind ldq --minify",
        "esbuild ldq --minify",
        "phx.digest"
      ]
    ]
  end
end
