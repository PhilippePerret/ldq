defmodule LdQWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use LdQWeb, :controller` and
  `use LdQWeb, :live_view`.
  """
  use LdQWeb, :html

  embed_templates "layouts/*"

  def main_links(assigns) do
    ~H"""
    <div class="main-links">
      <a class="main" href={~p"/"}>MANIFESTE</a>
      <a class="main" href={~p"/livres/choisir"}>Trouver un bon livre à lire</a>
      <a class="main" href={~p"/livres/classement"}>Classement des livres</a>
      <a class="main" href={~p"/livres/new"}>Proposer un livre</a>
      <a class="main" href={~p"/apropos/faq"}>F.A.Q.</a>
    </div>
    """
  end

end
