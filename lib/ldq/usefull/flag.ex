defmodule Flag do
  import Bitwise

  @doc """
  Pour savoir si un drapeau contient un bit

  ## Examples

    iex> Flag.has?(64, 64)
    true

    iex> Flag.has?(32, 64)
    false

    iex> Flag.has?(3, 1)
    true

    iex> Flag.has?(3, 2)
    true

    iex> Flag.has?(3, 3)
    true

  """
  def has?(flags, value), do: (flags &&& value) == value
end