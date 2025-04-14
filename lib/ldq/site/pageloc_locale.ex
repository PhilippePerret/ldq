defmodule Site.PageLocale.Locale do
  use Ecto.Type

  @locales %{
    "fr" => "Français",
    "en" => "Anglais",
    "es" => "Espagnol",
    "it" => "Italien",
    "de" => "Allemand"
  }

  def type, do: :string

  def cast(value) when is_binary(value) do
    if Map.has_key?(@locales, value), do: {:ok, value}, else: :error
  end

  def cast(_), do: :error

  def dump(value), do: cast(value)
  def load(value), do: cast(value)

  def values, do: Enum.map(@locales, fn {k, v} -> {v, k} end)
end