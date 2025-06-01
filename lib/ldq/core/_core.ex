defmodule LdQ.Core do
  @moduledoc """
  Module gérant le coeur de l'application.
  Ce module a été inauguré pour la table triggers qui consigne tous
  les triggers
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo


  alias LdQ.Core.Trigger

  def create_trigger!(attrs \\ %{}) do
    %Trigger{}
    |> Trigger.changeset(attrs)
    |> Repo.insert!()
  end

  def get_trigger(trigger_id) do
    trigger = Repo.get!(Trigger, trigger_id)
    %{trigger | data: Jason.decode!(trigger.data, keys: :atoms)}
  end

  
end