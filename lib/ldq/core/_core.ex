defmodule LdQ.Core do
  @moduledoc """
  Module gérant le coeur de l'application.
  Ce module a été inauguré pour la table triggers qui consigne tous
  les triggers
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo


  alias LdQ.Core.Trigger

  def create_trigger!(%attrs \\ %{}) do
    %Trigger{}
    |> Trigger.changeset(attrs)
    |> Repo.insert!()
  end

  
end