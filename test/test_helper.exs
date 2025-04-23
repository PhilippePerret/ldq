ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(LdQ.Repo, :manual)
Application.put_env(:wallaby, :base_url, LdQWeb.Endpoint.url())

Code.require_file("support/test_helpers.ex", __DIR__)
Code.require_file("support/feature_case.ex", __DIR__)
Code.require_file("support/feature_methods.ex", __DIR__)
