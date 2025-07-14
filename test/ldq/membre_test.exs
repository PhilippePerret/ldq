defmodule LdQ.MembreTest do
  use ExUnit.Case
  
  import FeaturePublicMethods

  alias LdQ.Comptes
  alias LdQ.Evaluation.Numbers, as: Calc

  setup do
    TestHelpers.reset_all()
  end

  describe "Méthode Comptes.Getters.get_user_as_membre!" do

    @tag :skip
    test "produit une erreur si le user n'existe pas" do
      assert_raise(LdQ.Error, "NotAUser", fn ->
        bad_id = Ecto.UUID.generate()
        Comptes.Getters.get_user_as_membre!(bad_id)
      end)
    end

    @tag :skip
    test "produit une erreur si le user n'est pas un membre du comité" do
      user = make_user(privileges: 0)
      assert_raise(LdQ.Error, "NotAMember", fn ->
        Comptes.Getters.get_user_as_membre!(user.id)
      end)
    end

    @tag :skip
    test "avec l'identifiant, retourne un membre avec des propriétés supplémentaires" do
      user = make_user(privileges: [:membre])
      membre = Comptes.Getters.get_user_as_membre!(user.id)
      refute(is_nil(membre.college))
    end

    @tag :skip
    test "avec le user, retourne un membre avec des propriétés supplémentaires" do
      user = make_user(privileges: [:membre])
      membre = Comptes.Getters.get_user_as_membre!(user)
      refute(is_nil(membre.college))
    end

    @tag :skip
    test "retourne un membre du collège 1, si crédit correspond" do
      user = make_user(privileges: [:membre], credit: Calc.points_for(:seuil_college_two) - 10)
      membre = Comptes.Getters.get_user_as_membre!(user.id)
      assert(membre.college == 1, "Le user #{inspect user} devrait être du premier collège… Son collège est #{inspect membre.college}")
    end

    @tag :skip
    test "retourne un membre du collège 2, si crédit correspond" do
      user = make_user(privileges: [:membre], credit: Calc.points_for(:seuil_college_three) - 10)
      membre = Comptes.Getters.get_user_as_membre!(user.id)
      assert(membre.college == 2, "Le user #{inspect user} devrait être du second collège… Son collège est #{inspect membre.college}")
    end

    # @tag :skip
    test "retourne un membre du collège 3, si crédit correspond" do
      user = make_user(privileges: [:membre], credit: Calc.points_for(:seuil_college_three) + 10)
      membre = Comptes.Getters.get_user_as_membre!(user.id)
      assert(membre.college == 3, "Le user #{inspect user} devrait être du premier collège… Son collège est #{inspect membre.college}")
    end

    @tag :skip
    test "retourne un membre même quand le membre est administrateur" do
      user = make_user(privileges: [:membre, :admin])
      membre = Comptes.Getters.get_user_as_membre!(user.id)
      refute(is_nil(membre.college))
    end

  end #/ méthode Comptes.Getters.get_user_as_membre!

end