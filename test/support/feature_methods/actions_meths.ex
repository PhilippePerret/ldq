defmodule Feature.ActionTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import TestHelpers
  import Feature.SessionMethods


  def visiter_la_page(session, url, added_to_msg \\ nil) do
    session = session_from(session)
    msg = "-> On rejoint la page #{url} #{added_to_msg}"
    w msg, :blue
    WB.visit(session, url)
  end

  def cliquer_le_bouton(session, button_name) do
    session = session_from(session)
    click(session, WQ.button(button_name))
  end

  def cliquer_le_lien(session, link_title) do
    session = session_from(session)
    click(session, WQ.link(link_title))
  end

end