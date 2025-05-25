defmodule Feature.ActionTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  # alias Wallaby.Element,  as: WE

  import Feature.SessionMethods
  import Feature.PageTestMethods


  def visiter_la_page(sujet, url, _added_to_msg \\ nil) do
    sujet = if Map.get(sujet, :session) do sujet else      
      {:ok, sess} = Wallaby.start_session()
      Map.put(sujet, :session, sess)
    end

    session = session_from(sujet)
    # msg = "-> On rejoint la page #{url} #{added_to_msg}"
    # w msg, :blue
    WB.visit(session, url)
    if on_login_page?(sujet) do
      FeaturePublicMethods.se_connecte(sujet)
    else 
      sujet 
    end
  end

  def cliquer_le_bouton(sujet, button_name) do
    session = session_from(sujet)
    click(session, WQ.button(button_name))
    sujet
  end

  def cliquer_le_lien(sujet, link_title) do
    session = session_from(sujet)
    click(session, WQ.link(link_title))
    sujet
  end

end