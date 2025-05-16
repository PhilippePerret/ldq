defmodule LdQ.Tests.Mails do
  @moduledoc """
  Ce module a été créé pour gérer les mails au cours des test. 
  Au commencement, on enregistrait ces mails dans un fichier, dans un
  dossier temporaire. Mais l'utilisation de bdd_dump/bdd_load pour 
  gérer les états des tests n'était plus pratique avec cette façon de
  faire. Maintenant, en mode test, les mails sont enregistrés dans la
  base de données.
  Noter qu'on y gagne beaucoup aussi en souplesse pour récupérer les 
  bons messages.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LdQ.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tests_mails" do
    field :to, :string
    field :from, :string
    field :subject, :string
    field :body, :string
    field :attachment, :string
    field :mail_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mail, attrs) do
    mail
    |> cast(attrs, [:to, :from, :subject, :body, :attachment, :mail_id])
    |> validate_required([:to, :from, :subject, :body])
  end

  @doc """
  Créer un mail dans la base pour les tests
  """
  def create(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
    |> Repo.insert!()
  end

  def get_all do
    Repo.all(__MODULE__)
  end

  def delete_all do
    Repo.delete_all(__MODULE__)
  end

  @doc """
  Recherche et retourne les mails correspondant aux paramètres 
  +params+
  """
  def find(params) do
    query = from(m in __MODULE__)
    # Les égalités strictes
    query =
      Enum.reduce([:to, :from, :attachment, :mail_id], query, fn prop, q ->
        if params[prop] do
          value = params[prop]
          where(q, [m], field(m, ^prop) == ^value)
        else 
          q 
        end
      end)
    # Les approximations ou groupes
    query =
      Enum.reduce([:body, :subject], query, fn prop, q ->
        expected_value = params[prop]
        cond do
        is_nil(expected_value) -> q
        is_list(expected_value) ->        
          Enum.reduce(expected_value, q, fn seg, q ->
            seg_like = "%#{seg}%"
            where(q, [m], ilike(field(m, ^prop), ^seg_like))
          end)
        is_binary(expected_value) -> 
          expect_like = "%#{expected_value}%"
          where(q, [m], ilike(field(m, ^prop), ^expect_like))
        true -> raise "Type inconnu pour la recherche de #{inspect prop} : #{inspect expected_value}"
        end
      end)
    query =
      if params[:after] do
        where(query, [m], m.inserted_at >= ^params.after)
      else query end
    query = 
      if params[:before] do
        where(query, [m], m.inserted_at <= ^params.before)
      else query end
    Repo.all(query)
  end

end
