defmodule LdQWeb.SpecPageController do
  @moduledoc """
  Traitement des pages spéciales
  """
  use LdQWeb, :controller

  @doc """
  Fonction atteinte par la route "/home"
  """
  def home(conn, _params) do
    attrs = %{}
    |> Map.put(:logs, Site.Log.get_lasts_public())
    render(conn, :home, attrs)
  end


end