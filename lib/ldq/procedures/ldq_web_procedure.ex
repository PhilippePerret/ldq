defmodule LdQWeb.Procedure do
  @moduledoc """
  Utiliser use LdQWeb.Procedure au début de toute nouvelle procédure
  elle pourra alors bénéficier de tout ce qu'il y a ci-dessous.
  """

  defmacro __using__(_) do

    quote do
      import LdQ.ProcedureMethods
      import LdQ.Site.PageHelpers # formlink, ldb_label etc.
      import Helpers.Feminines
      use Phoenix.Component
      import Html.Helpers
    
      alias LdQ.Comptes.User
    
    end
  end

end