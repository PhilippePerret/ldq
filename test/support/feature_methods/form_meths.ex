defmodule Feature.FormTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import Feature.SessionMethods

  def remplir_le_champ(sujet, champ) do
    session = session_from(sujet)
    fn valeur ->
      fill_in(session, WQ.text_field(champ), with: valeur)
      sujet
    end    
  end
  def avec(fonction, value) do
    fonction.(value)
  end

  @doc """
  Pour cocher une case (checkbox). On peut fournir soit le label, soit
  l'idenditifiant ou la classe propre par "#<id>" ou ".<class>" (mais
  dans ce cas il faut vraiment que le texte commence par # ou .)
  """
  def cocher_la_case(sujet, case_name) do
    session = session_from(sujet)
    if String.match?(case_name, ~r/^[\#\.]/) do
      click(session, WQ.css(case_name))
    else
      click(session, WQ.checkbox(case_name))
    end
    sujet
  end

  def coche_le_button_radio(sujet, radio_id) do
    session = session_from(sujet)
    click(session, WQ.radio_button(radio_id))
    sujet
  end

  @doc """
  Pour choisir le bon captcha dans un formulaire.
  S'il y a plusieurs formulaires, il faut indiquer dans +params+
  celui qu'il faut utiliser (par exemple avec son +id+ par :form_id)
  """
  def mettre_bon_captcha(session, params \\ %{}) do
    prefix = Map.get(params, :prefix, "f")
    session = session_from(session)
    # Récupérer l'index
    index_field = WQ.css("##{prefix}_captcha_index", visible: false)
    question_index = WB.find(session, index_field) |> WE.value() |> String.to_integer()
    data_question = Html.Form.get_captcha_at(question_index)
    # IO.inspect(data_question, label: "\nData question (captcha)")
    option_name = data_question.answer 
    choisir_menu(session, option_name, "#{prefix}_captcha")
  end


  def choisir_menu(session, option_value, select_id \\ nil) do
    session = session_from(session)
    selector = 
      if is_nil(select_id) do
        ~s(option[value="#{option_value}"])
      else
        ~s(select##{select_id} option[value="#{option_value}"])
      end
    WB.click(session, css(selector))
  end
end