defmodule LdQ.Procedure.CandidatureComite do
  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """
  import LdQ.ProcedureMethods
  import LdQ.Site.PageHelpers # formlink, ldb_label etc.
  import LdQ.Helpers.Feminines
  use Phoenix.Component
  alias LdQ.Comptes

  def proc_name, do: "Candidature au comité de lecture"

  @steps [
    %{name: "Formulaire de candidature", fun: :fill_candidature, admin_required: false, owner_required: false},
    %{name: "Soumission de la candidature", fun: :submit_candidature, admin_required: false, owner_required: true},
    %{name: "Accepter, refuser ou soumettre à un test", fun: :accepte_refuse_or_test, admin_required: true, owner_required: false},
    %{name: "Refus de la candidature", fun: :refuser_candidature, admin_required: true, owner_required: false},
    %{name: "Accepter la candidature", fun: :accepter_candidature, admin_required: true, owner_required: false},
    %{name: "Soumettre à un test", fun: :soumettre_a_test, admin_required: true, owner_required: false},
    %{name: "Passage du test", fun: :test, admin_required: false, owner_required: true}
  ] |> Enum.with_index() |> Enum.map(fn {s, index} -> Map.put(s, :index, index) end)
  def steps, do: @steps

  @doc """
  Fonction qui détermine (en fonction de la procédure) les données à
  enregistrer dans la table
  """
  def procedure_attributes(params) do
    user = params.user
    %{
      proc_dim:     "candidature-comite",
      owner_type:   "user",
      owner_id:     user.id,
      steps_done:   ["create"],
      current_step: "create",
      next_step:    "fill_candidature",
      data: %{
        user_id:    user.id,
        user_mail:  user.email,
        folder:     __DIR__
      }
    }
  end

  def philhtml_options(options \\ []) do
    options ++ [no_header: true, evaluation: false, no_file: true, helpers: [LdQWeb.ViewHelpers]]
  end

  @doc """

  @return {HTMLString} Le formulaire pour poser sa candidature.
  """
  def fill_candidature(procedure) do
    form = %Html.Form{
      id: "candidature-comite", 
      action: "/proc/#{procedure.id}",
      captcha: true,
      fields: [
        %{tag: :hidden, name: "procedure_id", value: procedure.id},
        %{tag: :input, type: :hidden, strict_name: "nstep", value: "submit_candidature"},
        %{tag: :textarea, name: "motivation", label: "Motivation", required: true, explication: "Merci d'expliquer en quelques mots vos motivations."},
        %{tag: :input, type: :text, name: "genres", label: "Genres de prédilection", explication: "Si vous avez des genres littéraires de prédilection, merci de les indiquer en les séparant par une virgule."}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre"}
      ]
    }
    
    """
    <p>Vous voulez donc rejoindre le comité de lecture du label #{ldq_label()} en tant que lect#{fem("rice", procedure.user)} et nous vous en remercions.</p>
    <p>Voici quelques pages que vous pourriez lire afin de valider votre souhait.</p>
    <ul>
      <li>#{pagelink("Choix des membres du comité de lecture","choix-membres","member-submit#attention")}</li>
      <li>#{pagelink("Engagement des membres du comité de lecture","engagement-membres","member-submit#attention")}</li>
    </ul>
    
    <h3>Formulaire de soumission de la candidature</h3>

    #{Html.Form.formate(form)}
    """
  end

  def submit_candidature(procedure) do
    IO.inspect(procedure, label: "\nProcédure à l'entrée de submit_candidature")
    form_values = procedure.params["f"]
    if Html.Form.captcha_valid?(form_values) do
      user = get_owner(procedure)
      params = procedure.params

      data = procedure.data
      data = Map.merge(data, %{
        motivation: form_values["motivation"],
        genres:     form_values["genres"] |> String.split() |> Enum.map(&String.trim/1) |> Enum.filter(fn g -> g != "" end),
        submit_candidature_at: NaiveDateTime.utc_now() 
      })
  
      new_proc_attrs = %{
        data: data,
        next_step: "accepte_refuse_or_test"
      }
      procedure = update_procedure(procedure, new_proc_attrs)
  
      mail_data = %{
        mail_id:    nil,
        procedure:  procedure,
        user:       user,
        folder:     __DIR__
      }
  
      send_mail(:admin, user.email, %{mail_data | mail_id: "user-candidature-recue"})
      send_mail(user.email, :admins, %{mail_data | mail_id: "admin-new-candidature"})
      # notify(%{
      #   notif_dim:      "accepte_refuse_or_test",
      #   procedure_id:   procedure.id,
      #   group_target:   "admins",
      #   title:          "Accepter, refuser, ou demander de passer le test pour une candidature au comité de lecture",
      #   body:             """
      #   <select name="notif[action]">
      #     <option value="accept">Accepter la candidature</option>
      #     <option value="refuse">Refuser la candidature</option>
      #     <option value="tester">Demander à passer le test</option>
      #   </select>
      #   <label>Motif du refus</label>
      #   <textearea name="notif[raison]"></textarea>
      #   <div class="buttons"><button>Soumettre</button></div>
      #   """,
      #   data:             data,
      #   action_required:  true
      # })

      """
      <p>Fin de la procédure</p>
      """
  
    else "<p>Seul un humain ou une humaine peut entamer cette procédure, désolé.</p>" end
  end

  def accepte_refuse_or_test(procedure) do
    user = get_owner(procedure)
    """
    <div class="procedure">
    <p>#{user_link(user, [target: :blank])} vient de poser sa candidature pour le comité de lecture.</p>
    <div class="links-in-line">
      <a class="btn" href="/proc/#{procedure.id}?nstep=accepter_candidature">Accepter</a>
      <a class="btn" href="/proc/#{procedure.id}?nstep=refuser_candidature">Refuser</a>
      <a class="btn" href="/proc/#{procedure.id}?nstep=soumettre_a_test">Soumettre à test</a>
    </div>
    <p>{Ici des liens supplémentaires pour demander au candidat, par exemple, de préciser des choses sur son profil}</p>
    </div>
    """
  end

  @doc """
  Ce n'est pas la fonction qui procède au refus, c'est la fonction
  qui va permettre de le faire.
  """
  def refuser_candidature(procedure) do
    """
    Je dois procéder au refus de la candidature
    """
  end



  def proceed_refus_candidature(procedure) do
    params = %{} # Pour le moment
    raison = if params["notif"]["raison"] == "" do "Aucune" else
      String.trim(params["notif"]["raison"])
    end
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("raison", raison)
    |> Map.put("mail_id", "user-soumission-refused")

    send_mail(procedure.user.mail, :admins, params)
    delete_procedure(procedure)
  end

  def accepter_candidature(procedure) do
    """
    <p>Je dois procéder à l'acceptatioin du membre dans le comité de lecture.</p>
    """
  end
  def proceed_acceptation_candidature(procedure) do
    params = %{} # Pour le moment
    user = get_user(procedure)
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("mail_id", "user-soumission-success")
    send_mail(user.mail, :admins, params)
  end

  def soumettre_a_test(procedure) do
    """
    <p>Je dois demander au candidat de passer le test</p>
    """
  end
  def proceed_soumission_a_test(procedure) do
    params = %{} # Pour le moment
    
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("mail_id", "user-soumission-test")
    send_mail(procedure.user.mail, :admins, params)
  end

end