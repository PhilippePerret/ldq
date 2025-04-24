defmodule LdQ.ComptesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Comptes` context.
  """

  def uniq_int() do
    System.unique_integer([:positive, :monotonic])
  end

  def unique_user_email, do: "user#{uniq_int()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: Map.get(attrs, :name, "Stranger-#{uniq_int()}"),
      email: unique_user_email(),
      sexe: "F", 
      password: Map.get(attrs, :password, valid_user_password())
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> LdQ.Comptes.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
