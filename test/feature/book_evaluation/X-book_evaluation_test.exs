defmodule LdQWeb.BookSubmissionTests do
  @moduledoc """
  Module de test permettant de tester l'évaluation d'un livre, depuis
  sa soumission jusqu'à l'attribution de son label (ou pas).
  Ce module unique permet de tester les choses quand tout va bien et
  que le livre passe toutes les étapes.
  On se sert intenséement de bdd_dump et bdd_load pour repartir d'un
  point précis de la base.

  """
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import FeaturePublicMethods
  import TestHelpers

  @tag :skip 
  test "Un visiteur inconnu ne peut pas soumettre un livre" do
    # TODO
  end

  # @tag :skip
  @tag :skip
  test "Soumission d'un livre par quelqu'un d'autre que l'auteur" do
  end
  @tag :skip
  test "Après soumission, un auteur non enregistrer doit s'enregistrer avant de confirmer la soumission" do
  end

  @tag :skip
  test "Un non inscrit ne peut pas soumettre un livre" do
  end

  @tag :skip
  test "On ne peut pas soumettre de force un formulaire incomplet" do
  end

  @tag :skip
  test "On peut soumettre un livre directement par formulaire" do
  end

  @tag :skip
  test "On ne peut pas soumettre deux fois le même livre" do
  end

  @tag :skip
  test "Soumission par quelqu'un d'autre que l'auteur" do
    # L'auteur reçoit un mail aussi
  end

end