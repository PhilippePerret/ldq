ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(LdQ.Repo, :manual)
Application.put_env(:wallaby, :base_url, LdQWeb.Endpoint.url())

Code.require_file("support/feature_case.ex", __DIR__)

defmodule TestHelpers do

  def w(str, color \\ :white) do
    params = case color do
      :white  -> [IO.ANSI.white(), str, IO.ANSI.reset()]
      :red    -> [IO.ANSI.red(), str, IO.ANSI.reset()]
      :blue   -> [IO.ANSI.blue(), str, IO.ANSI.reset()]
      :grey   -> IO.ANSI.format(["color:200,200,200", str, :reset])
    end
    IO.puts params
  end

  @doc """
  Pour pauser dans un pipe
  Note : hors d'un pipe, mettre nil en premier argument
  """
  def pause(traversor, quantite, unit \\ :seconde) do
    ms = case unit do
      :minute   -> quantite * 60
      :seconde  -> quantite
    end
    Process.sleep(ms * 1000)

    traversor
  end

end

defmodule FeaturesMethods do
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

  def je_remplis_le_champ(session, champ) do
    fn valeur ->
      fill_in(session, WQ.text_field(champ), with: valeur)
    end    
  end
  def avec(fonction, value) do
    fonction.(value)
  end

  def je_coche_la_case(session, case_name) do
    click(session, WQ.checkbox(case_name))
  end

  def je_clique_le_bouton(session, button_name) do
    click(session, WQ.button(button_name))
  end


  # ---- Méthodes de test --------

  def la_page_contient(session, balise, searched) when is_binary(searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      WE.text(el) =~ searched 
    end)
    session
  end
  def la_page_contient(session, balise, searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      Regex.match?(searched, WE.text(el))
    end)
    session
  end
  def la_page_contient(session, searched) do
    searched = if is_binary(searched) do
      ~r/#{searched}/
    else searched end
    assert Regex.match?(searched, WB.page_source(session))
    session
  end

end