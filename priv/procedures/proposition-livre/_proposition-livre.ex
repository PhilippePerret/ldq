defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité jusqu'à sa mise en test.
  Donc il ne s'agit que du début de la longue procédure.
  """
  use LdQWeb.Procedure

  def proc_name, do: "Soumission d’un livre"

  @steps [
    %{name: "Proposition du livre", fun: :proposition_livre, admin_required: false, owner_required: false},
    %{name: "Soumission par l'ISBN", fun: :submit_book_with_isbn, admin_required: false, owner_required: true},
    %{name: "Soumission par formulaire", fun: :submit_book_with_form, admin_required: false, owner_required: true}
  ]
  def steps, do: @steps


  @doc """
  Fonction qui détermine (en fonction de la procédure) les données à
  enregistrer dans la table
  """
  def procedure_attributes(params) do
    user = params.user
    %{
      proc_dim:     "proposition-livre",
      owner_type:   "user",
      owner_id:     user.id,
      steps_done:   ["create"],
      current_step: "create",
      next_step:    "proposition_livre",
      data: %{
        user_id:    user.id,
        user_mail:  user.email,
        folder:     __DIR__
      }
    }
  end


  @doc """
  Fonction appelée pour permettre à l'utilisateur de proposer un
  livre au label. Elle lui présente la chose
  """
  def proposition_livre(procedure) do
    user = procedure.user

    form_with_isbn = Html.Form.formate(%Html.Form{
      id: "form-submit-with-isbn",
      captcha: true,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "submit_book_with_isbn"},
        %{type: :text, name: "isbn", label: "ISBN du livre"},
        %{type: :checkbox, name: "is_author", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre par ISBN"}
      ]
    })

    form_with_form = Html.Form.formate(%Html.Form{
      id: "form-submit-with-form",
      captcha: true,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "submit_book_with_form"},
        %{type: :checkbox, name: "is_author", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre par formulaire"}
      ]

    })
    """
    <p>#{user.name}, pour proposer un livre, vous devez en être l'autrice ou l'auteur OU 
    être en possession des informations sur l'auteur, à minima connaitre son
    adresse de courriel afin que nous puissions le contacter.</p>

    <div class="colonnes">
      <div class="col1">#{form_with_isbn}</div>
      <div class="col2">#{form_with_form}</div>
    </div>
    """
  end

  @doc """
  Soumission du livre par son ISBN. En fait, la fonction relève les
  informations qu'elle peut trouver sur le net et appelle la fonction
  normale qui utilise un formulaire pour le peupler.
  """
  def submit_book_with_isbn(procedure) do

    """
    <p class=warning>Pour le moment, je m'arrête ici avec #{inspect procedure.params} mais ensuite je devrai appeler la méthode suivante.</p>
    """
  end

  def submit_book_with_form(procedure) do
    user = procedure.user
    book = if procedure.has_key?(:book) do
      # Quand l'user a demandé la soumission par ISBN et que les
      # information du livre ont pu être récupérées
      procedure.book
    else %{} end

    """
    <p class=warning>Je dois mettre le formulaire de soumission ici</p>
    """
  end

  def consigne(procedure) do
    book = procedure.params["book"]
    |> IO.inspect(label: "Paramètres du livre")

    # TODO Avertir l'administration

    # TODO Confirmation à l'auteur que le livre a bien été enregistré

    """
    <p>Merci pour cette proposition de livre.</p>
    <p>Voilà ce qui va se passer ensuite :</p>
    <ul>
    </ul>
    """
  end
end