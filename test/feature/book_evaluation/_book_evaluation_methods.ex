defmodule BookEvaluationMethods do
  @moduledoc """
  Pour utiliser ces méthodes, placer : 

    Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

  … tout en haut du fichier.exs et :

    import BookEvaluationMethods

  … dans la définition du module de test
  """

  def get_book_of_proc(procedure) do
    procedure.data["book_id"]
    |> LdQ.Library.Book.get(:all)
  end

  def get_user_of_proc(procedure) do
    procedure.data["user_id"]
    |> LdQ.Comptes.Getters.get_user!()
  end

  def get_author_of_proc(procedure) do
    procedure.data["author_id"]
    |> LdQ.Library.get_author!()
  end

end