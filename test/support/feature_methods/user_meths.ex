defmodule Feature.UserTestMethods do
  use ExUnit.Case
  alias LdQ.Repo
  import Ecto.Query

  import LdQ.Comptes.User, only: [has_bit?: 2]

  def has_privileges(user, bit) do
    err_msg = "#{user.name} n'a pas le niveau de privilèges attendu.\n  Expected: #{bit}\n  Actual: #{user.privileges}"
    assert(has_bit?(user, bit), err_msg)
    user
  end
  def has_not_privileges(user, bit) do
    err_msg = "#{user.name} ne devrait pas avoir le niveau de privilèges #{bit}.\n  Actual: #{user.privileges}"
    refute(has_bit?(user, bit), err_msg)
    user
  end

  # S'assure que l'auteur existe
  # @return L'auteur (si aucun nombre n'a été spécifié ou 1) ou la
  # liste des authors dans le cas contraire.
  def assert_author_exists(params) do
    query = from(w in LdQ.Library.Author)
    query = if params[:after] do
      where(query, [w], w.inserted_at > ^params[:after])
    else query end
    query = 
      [:email, :firstname, :lastname]
      |> Enum.reduce(query, fn prop, qu ->
        if params[prop] do
          where(qu, [w], w[prop] == ^params[prop])
        else qu end
      end)
    # --- Vérification ---
    authors = Repo.all(query)
    nb_founds = Enum.count(authors)
    nb_expect = (params[:count] || 1)
    assert(nb_founds == nb_expect, "On devrait avoir trouvé #{nb_expect} author(s), on en a trouvé #{nb_founds}…")
    if nb_expect == 1 do
      Enum.at(authors, 0)
    else
      authors
    end
  end
  
end