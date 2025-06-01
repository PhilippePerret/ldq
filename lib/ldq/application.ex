# defmodule CertTest do
#   def check_cert do
#     File.read!("/home/icare/www/label/fullchain.pem")
#     |> IO.inspect(label: "Certificat")
#   end
# end

defmodule LdQ.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LdQWeb.Telemetry,
      LdQ.Repo,
      {DNSCluster, query: Application.get_env(:ldq, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LdQ.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LdQ.Finch},
      # Start a worker by calling: LdQ.Worker.start_link(arg)
      # {LdQ.Worker, arg},
      # Start to serve requests, typically the last entry
      LdQWeb.Endpoint
    ]
    
    # Sauf en mode test, on lance le démon des triggers qui va les
    # vérifier toutes les heures.
    children = unless Mix.env() == :test do
      [{LdQ.Core.TriggerDaemon, []} | children]
    else children end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LdQ.Supervisor]
    Supervisor.start_link(children, opts)
    LdQ.Procedure.start_agent()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LdQWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
