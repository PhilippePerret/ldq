defmodule Feature.ActionTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import TestHelpers

  def je_rejoins_la_page(session, url, added_to_msg \\ nil) do
    msg = "-> Je rejoins la page #{url} #{added_to_msg}"
    w msg, :blue
    WB.visit(session, url)
  end

  def je_clique_le_bouton(session, button_name) do
    click(session, WQ.button(button_name))
  end

  def je_clique_le_lien(session, link_title) do
    click(session, WQ.link(link_title))
  end

end