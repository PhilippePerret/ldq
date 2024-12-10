defmodule LdQ.Repo do
  use Ecto.Repo,
    otp_app: :ldq,
    adapter: Ecto.Adapters.Postgres
end
