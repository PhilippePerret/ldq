defmodule Feature.FormTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

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

  @doc """
  Pour choisir le bon captcha dans un formulaire.
  S'il y a plusieurs formulaires, il faut indiquer dans +params+
  celui qu'il faut utiliser (par exemple avec son +id+ par :form_id)
  """
  def je_mets_le_bon_captcha(session, params \\ %{}) do
    # Récupérer l'index
    index_field = WQ.css("#captcha_index", visible: false)
    question_index = WB.find(session, index_field) |> WE.value() |> String.to_integer()
    data_question = Html.Form.get_captcha_at(question_index)
    IO.inspect(data_question, label: "\nData question (captcha)")
    option_name = data_question.answer 
    choisir_le_menu(session, option_name, "captcha")
  end


  def choisir_le_menu(session, option_value, select_id \\ nil) do
    selector = 
      if is_nil(select_id) do
        ~s(option[value="#{option_value}"])
      else
        ~s(select##{select_id} option[value="#{option_value}"])
      end
    WB.click(session, css(selector))
  end
end