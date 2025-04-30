defmodule LdQ.ComptesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Comptes` context.
  """

  alias LdQ.Comptes
  import Bitwise

  def uniq_int() do
    System.unique_integer([:positive, :monotonic])
  end

  def unique_user_email, do: "user#{uniq_int()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(nil), do: valid_user_attributes(%{})
  def valid_user_attributes(attrs \\ %{}) do
    Map.merge(attrs, %{
      name: Map.get(attrs, :name, "Stranger-#{uniq_int()}"),
      email: unique_user_email(),
      sexe: "F", 
      password: Map.get(attrs, :password, valid_user_password())
    })
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

  def make_admin(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Ben #{uniq_int()} Admin"),
      email:      "admin@lecture-de-qualite.fr",
      password:   Map.get(params, :password, valid_user_password()),
      privileges: Map.get(params, :privileges, [:admin3])
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  def make_member(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Brigitte #{uniq_int()} Membre"),
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, "F"),
      privileges: [:member]
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  def make_writer(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Caro#{uniq_int()} Autrice"),
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, "F"),
      privileges: [:writer]
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

end
