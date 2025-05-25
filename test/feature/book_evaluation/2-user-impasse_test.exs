defmodule LdQWeb.BookSubmissionTestsStep2_3 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  @tag :user
  test "Un user quelconque, même inscrit, ne peut pas rejoindre cette procédure" do
    %{procedure: procedure} = bddshot("evaluation-book/1-book-just-submitted")

    user = make_user_with_session(%{password: "monpassepartout"})

    user
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(4)
    |> et_voit("rien à faire sur cette page")
    |> end_session()
  end

end