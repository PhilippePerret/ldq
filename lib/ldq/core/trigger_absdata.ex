defmodule LdQ.Core.TriggerAbsdata do
  @moduledoc """
  DATA ABSOLUES DES TRIGGERS
  :uniq_scope       {String} Pour composer le scope unique du trigger qui empêchera d'en enregistrer deux identiques. On peut le composer en se servant des données qui seront consignées dans :data. Par exemple, si on a la clé :book_id dans :data, on peut utiliser : "${book_id}" dans le uniq_scope. Par exemple : evalbook:${book_id}. Le ${book_id} sera alors remplacer par la valeur :book_id de :data, donc l'identifiant du livre.
  :required_data    {Map} Les données requises pour pouvoir évaluer le trigger. Il est impératif de les fournir à la création du trigger, sinon l'application raise.
  :duration         {Duplet {unité, quantité}} La durée après laquelle le trigger se déclenche.
  :recond_duration  {idem} La durée de reconduction SEULEMENT SI elle n'est pas la moitié du :duration
  :error_msg        {String} Le message en cas d'erreur, c'est-à-dire lorsque le résultat/action/opération attendu n'a pas été exécuté ou atteint.
                    Ce message est envoyé en notification à l'administration.
                    Ce message peut contenir des variables (TODO voir comment)
  :success_msg      {String} Le message en cas de succès. Ne sert que pour l'historique du module.
  :priority         {Integer} Nombre qui augmente à mesure des reconductions ou crée une priorité
  """
  defstruct [
    name:               nil,
    duration:           nil,
    recond_duration:    nil,
    required_data:      %{},
    error_msg:          nil,
    success_msg:        nil,
    uniq_scope:         nil,
    priority:           0
  ]


  def triggers_data do
    %{
      # TRIGGER qui s'assure qu'un livre est évalué dans le temps
      # minimum imparti.
      "evaluation-book" => %__MODULE__{
        duration: {:month, 6},
        required_data: %{book_id: "Identifiant du livre", procedure_id: "Identifiant de la procédure gérant l'évaluation du livre"},
        error_msg: "Le livre ${book_ref} devait être évalué.",
        success_msg: "Le livre ${book_ref} a été évalué dans les temps.",
        uniq_scope: "evalbook:${book_id}"
      },
      # TRIGGER qui s'assure que le quorum du premier collège est
      # atteint dans les temps.
      "deadline-quorum-college-1" => %__MODULE__{
        name: "Quand l'administrateur valide un livre pour évaluation",
        duration: {:day, 30},
        required_data: %{book_id: "Identifiant du livre", procedure_id: "Identifiant de la procédure"},
        error_msg: "Le quorum de ${nombre_membres_college1} membres du premier collège du comité de lecture devrait avoir été atteint",
        success_msg: "Le quorum de membres du collège 1 a été atteint",
        uniq_scope: "quorumcoll1:${book_id}"
      },
      # TRIGGER qui s'assure que le quorum du second collège est
      # atteint dans les temps.
      "deadline-quorum-college-2" => %__MODULE__{
        name: "Quand le livre passe au second collège",
        duration: {:day, 30},
        required_data: %{book_id: "Identifiant du livre"},
        error_msg: "Le quorum de ${nombre_membres_college2} membres du second collège du comité de lecture devrait avoir été atteint",
        success_msg: "Le quorum de membres du collège 2 a été atteint",
        uniq_scope: "quorumcoll2:${book_id}"
      },
      # TRIGGER qui s'assure que le quorum du troisième collège est
      # atteint dans les temps.
      "deadline-quorum-college-3" => %__MODULE__{
        name: "Quand le livre passe au troisième collège",
        duration: {:day, 30},
        required_data: %{book_id: "Identifiant du livre"},
        error_msg: "Le quorum de ${nombre_membres_college3} membres du troisième collège du comité de lecture devrait avoir été atteint",
        success_msg: "Le quorum de membres du collège 3 a été atteint",
        uniq_scope: "quorumcoll3:${book_id}"
      },
    }
  end

  @doc """
  @return {Map} Les données absolues pour le trigger +trigger+ ou
  son type.
  """
  def data(trigger_type) when is_binary(trigger_type) do
    absdata = triggers_data()[trigger_type] || raise(ArgumentError, "Le trigger de type #{inspect trigger_type} est inconnu.")
    %{absdata | recond_duration: calc_recond_duration_if_neccessary(absdata)}
  end
  def data(%{type: type} = _trigger), do: data(type)


  # @data_messages %{
  #   book_ref: nil, # référence du livre (book_id doit avoir été défini)
  #   nombre_membres_college1: nil,
  #   nombre_membres_college2: nil,
  #   nombre_membres_college3: nil
  # }
  def data_message(trigger) do
    # data = trigger.data
    triggers_data()[trigger.type]
  end


  # Calcule la durée de reconduction si nécessaire
  defp calc_recond_duration_if_neccessary(absdata) do
    if absdata.recond_duration do 
      absdata.recond_duration
    else
      {unity, quantity} = absdata.duration
      moitie = quantity / 2
      if moitie == round(moitie) do
        {unity, round(moitie)}
      else
        case unity do
          :month  -> {:day, round(quantity * 30 / 2)}
          :day    -> {:minute, round(quantity * 24 * 60 / 2)}
          _       -> {unity, round(moitie)} # au pire
        end
      end
    end
  end

end