defmodule LdQWeb.HomePageTest do
  @moduledoc """
  Module de test pour tester la page d'accueil
  (quand ce n'est pas la page affichant le manifeste)
  """
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturePublicMethods # Méthodes rejoint_la_page, etc.

  describe "La page d'accueil" do

    feature "affiche les bons logs", %{session: session} do
      logs = create_log(count: 30)
      the_ten_last_logs = 
        logs
        |> Enum.sort_by(&(&1.inserted_at), {:desc, Date})
        |> Enum.slice(0, 10)
        |> Enum.map(&(&1.text))
        |> Enum.join("\n")

      user = Map.put(make_simple_user(), :session, session)

      user
      |> rejoint_la_page("/home")
      |> pause(2)
      |> et_voit("h2", "Accueil du label")
      |> et_voit(the_ten_last_logs)
    end

  end #/describe "La page d'accueil"
end