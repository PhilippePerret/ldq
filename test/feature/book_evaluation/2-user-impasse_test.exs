defmodule LdQWeb.BookSubmissionTestsStep2_3 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  test "Un user quelconque, même inscrit, ne peut pas rejoindre cette procédure" do
    %{admin: admin, procedure: procedure, point_test: point_test} = bdd_load("book-just-submitted")

    user = make_user_with_session(%{password: "monpassepartout"})

    user
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(10)
    |> et_voit("Voie sans issue")
    |> end_session()
  end

end