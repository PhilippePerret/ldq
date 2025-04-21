import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ldq, LdQ.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ldq_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :ldq, env: :test

config :ldq, LdQWeb.Gettext, default_locale: "fr"


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ldq, LdQWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "S1Pdk9ZEqh/VmadAxayZLPvCRel0VyMmPmbMGVBfRiprdpANtdjC3qGd3HmT93Pe",
  # server: false
  server: true # Pour wallaby

# In test we don't send emails
config :ldq, LdQ.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :wallaby,
  driver: Wallaby.Chrome,
  chrome: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  chromedriver: [
    # headless: true
    headless: false, # pour voir la page s'ouvrir
    capabilities: %{
      chromeOptions: %{ args: ["--window-size=1200,1400"] }
    }
  ]