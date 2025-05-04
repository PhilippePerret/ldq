defmodule LdQ.DocTestTests do
  @moduledoc """
  Pour tester tous les doctests un peu partout
  """
  use ExUnit.Case

  import Html.Helpers
  doctest Html.Helpers

  doctest Flag


end