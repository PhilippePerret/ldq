defmodule LdQ.ComptesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Comptes` context.
  """
  alias Random.Methods, as: Rand
  alias LdQ.Comptes
  import Bitwise
  import LdQ.LibraryFixtures


  def unique_user_email, do: "user#{Rand.uniq_int()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(a \\ %{})
  def valid_user_attributes(nil), do: valid_user_attributes(%{})
  def valid_user_attributes(attrs) do
    [
      :name, :email, :sexe, :password
    ] |> Enum.reduce(attrs, fn prop, attrs ->
      if is_nil(Map.get(attrs, prop, nil)) do
        val =
        case prop do
          :name     -> "Stranger-#{Rand.uniq_int()}"
          :email    -> unique_user_email()
          :sexe     -> "F"
          :password -> valid_user_password()
        end
        Map.put(attrs, prop, val)
      else
        attrs
      end
    end)
  end

  def user_fixture(attrs \\ %{}) do
    attrs = rationnalize_user_attributes(attrs)
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Comptes.register_user()
    user
  end

  # Transforme la donnée :privileges en entier si elle est données
  # une liste de privilèges
  defp rationnalize_user_attributes(attrs) do
    attrs = 
      if Map.has_key?(attrs, :privileges) and is_list(attrs.privileges) do
        bit_liste   = Comptes.User.table_bit_privileges
        priv_int = 
        Enum.reduce(attrs.privileges, 0, fn priv, val ->
          bor(val, bit_liste[priv])
        end)
        %{attrs | privileges: priv_int}
      else
        attrs        
      end
    attrs
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def make_simple_user(params \\ %{}) do
    new_attrs = %{
      password: Map.get(params, :password, valid_user_password()),
      privileges: 0
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  @doc """
  Contrairement aux users et autres authors, il n'y a pour le moment 
  qu'un seul administrateur, avec le mail :
  "admin@lecture-de-qualite.fr"
  S'il est déjà créé, on le retourne, sinon on le crée.
  """
  def make_admin(params \\ %{}) do
    email_admin     = "admin@lecture-de-qualite.fr"
    password_admin  = "passworddadministrateurpassepartout"
    case get_admin(Map.merge(%{email: email_admin}, params)) do
    {:ok, admin} -> admin
    :unknown ->
      his_number = Rand.uniq_int()
      new_attrs = %{
        name:       Map.get(params, :name, "Ben #{his_number} Admin"),
        email:      email_admin,
        password:   Map.get(params, :password, password_admin),
        privileges: Map.get(params, :privileges, [:admin3])
      }
      user_fixture(Map.merge(params, new_attrs))
    end |> Map.put(:password, params[:password] || password_admin)
  end

  def get_admin(params \\ %{email: "admin@lecture-de-qualite.fr"}) do
    case Comptes.get_user_by_email(params.email) do
    nil -> :unknown
    admin -> {:ok, admin}
    end
  end
  
  def make_member(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Brigitte #{Rand.uniq_int()} Membre"),
      email:      "membre-comite@lecture-de-qualite.fr",
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, "F"),
      privileges: [:member]
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  # Cette méthode semble un vieil héritage de l'époque où les auteurs
  # des livres étaient des User spéciaux. Maintenant, les auteurs des
  # livres sont des LdQ.Library.Author (cf. make_author/2)
  def make_writer(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Caro#{Rand.uniq_int()} Autrice"),
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, "F"),
      privileges: [:writer]
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  def make_author(params \\ %{}), do: author_fixture(params)

end
