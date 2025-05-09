defmodule Site.PageLocale.Status do
  use Ecto.Type

  @status %{
    0 => "En projet",
    1 => "Amorcée",
    2 => "En cours de rédaction",
    3 => "À relire",
    4 => "À corriger",
    5 => "À valider",
    6 => "Validée",
    9 => "Publiée"
  }

  def type, do: :string

  def get(status_id) do
    case cast(status_id) do
    {:ok, _} -> Map.get(@status, status_id)
    :error -> "- statut inconnu -"
    end
  end

  def cast(value) when is_integer(value) do
    if Map.has_key?(@status, value) do
      {:ok, value}
    else
      :error
    end
  end

  def cast(value) when is_binary(value) do
    cast(String.to_integer(value))
  end
  def cast(_), do: :error

  def dump(value), do: cast(value)
  def load(value), do: cast(value)

  # Pour menu select
  def values do
    Enum.map(@status, fn {k, v} -> {v, k} end)
  end

end