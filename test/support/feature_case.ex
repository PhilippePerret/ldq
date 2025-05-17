defmodule LdQWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      alias LdQ.Repo
      import Ecto.Query
      import Wallaby.Query
      # import LdQWeb.Gettext

      import LdQ.ComptesFixtures

      @endpoint LdQWeb.Endpoint
    end
  end

  setup _tags do

    # Puisqu'on n'utilise plus la sandbox pour pouvoir faire des
    # photographies de la BdD, on doit forcer le vidage de la base 
    # de données avant chaque test.
    TestHelpers.bdd_reset()

    # Tout le code ci-dessous supprimé permet de ne pas utiliser
    # la sandbox (Photographies de la BdD)
    # -----------------------------------------------------------
    # :ok = Ecto.Adapters.SQL.Sandbox.checkout(LdQ.Repo)
    # unless tags[:async] do
    #   Ecto.Adapters.SQL.Sandbox.mode(LdQ.Repo, {:shared, self()})
    # end
    # metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(LdQ.Repo, self())

    {:ok, session} = Wallaby.start_session([
      # metadata: metadata,
      window_size: [width: 1000, height: 1200]
      ])
    {:ok, session: session}
  end
end