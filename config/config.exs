# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ldq,
  namespace: LdQ,
  ecto_repos: [LdQ.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :ldq, LdQWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LdQWeb.ErrorHTML, json: LdQWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LdQ.PubSub,
  live_view: [signing_salt: "skVaipVa"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ldq, LdQ.Mailer, adapter: Swoosh.Adapters.Local

# Pour pouvoir utiliser le numéro de version
config :ldq, :app_version, LdQ.MixProject.project()[:version]

config :ldq, LdQWeb.Gettext, default_locale: "fr"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ldq: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ldq: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# --- Pour Markdown ---
# config :phoenix, :template_engines, md: PhoenixMarkdown.Engine
# config :phoenix_markdown, :server_tags, :all
# config :phoenix_markdown, :earmark, %{
#     gfm: true,
#     smartypants: false,
#     breaks: true
#   }

# --- Pour mon markdown à moi ---
config :phoenix, :template_engines, 
  md:  PPMarkdown.Engine,
  mmd: PPMarkdown.Engine
config :pp_markdown, options: %{
  server_tags: :all,
  gfm: true, 
  smartypants: false,
  breaks: true
}
config :pp_markdown, table_vars: %{
  label_ldq: "<span class=\"label\">Lecture de Qualité</span>"
}


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
