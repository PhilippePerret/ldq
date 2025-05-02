defmodule LdQ.Procedure.CandidatureComite do
  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """
  import LdQ.ProcedureMethods
  import LdQ.Site.PageHelpers # formlink, ldb_label etc.
  import Helpers.Feminines
  use Phoenix.Component
  
  alias LdQ.Comptes.User

  def proc_name, do: "Candidature au comité de lecture"

  @steps [
    %{name: "Formulaire de candidature", fun: :fill_candidature, admin_required: false, owner_required: false},
    %{name: "Soumission de la candidature", fun: :submit_candidature, admin_required: false, owner_required: true},
    %{name: "Accepter, refuser ou soumettre à un test", fun: :accepte_refuse_or_test, admin_required: true, owner_required: false},
    %{name: "Accepter la candidature", fun: :accepter_candidature, admin_required: true, owner_required: false},
    %{name: "Procéder à l'acceptation", fun: :proceed_acceptation_candidature, admin_required: true, owner_required: false},
    %{name: "Refus de la candidature", fun: :refuser_candidature, admin_required: true, owner_required: false},
    %{name: "Procéder au refus", fun: :proceed_refus_candidature, admin_required: true, owner_required: false},
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
      <li>#{pagelink("Choix des membres du comité de lecture","choix-membres","url:/proc/new/candidature-comite")}</li>
      <li>#{pagelink("Engagement des membres du comité de lecture","engagement-membres","url:/proc/new/candidature-comite")}</li>
    </ul>
    
    <h3>Formulaire de soumission de la candidature</h3>

    #{Html.Form.formate(form)}
    """
  end

  @doc """
  Le candidat rejoint cette étape quand il soumet sa candidature pour
  le comité de lecture.
  On l'enregistre et on prévient l'administration.
  """
  def submit_candidature(procedure) do
    # IO.inspect(procedure, label: "\nProcédure à l'entrée de submit_candidature")
    form_values = procedure.params["f"]
    if Html.Form.captcha_valid?(form_values) do
      user = get_owner(procedure)
      _params = procedure.params

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
  
      send_mail(to: user, from: :admin, with: %{mail_data | mail_id: "user-candidature-recue"})
      send_mail(to: :admins, from: user, with: %{mail_data | mail_id: "admin-new-candidature"})

      load_phil_text(__DIR__, "submit_candidature", %{user: user})
    else 
      # Quand le captcha est mauvais
      "<p>Seul un humain ou une humaine peut entamer cette procédure, désolé.</p>" 
    end
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
  qui va permettre de le faire. Elle affiche le formulaire pour 
  donner le motif du refus.
  """
  def refuser_candidature(procedure) do
    form = %Html.Form{
      id: "refus-form",
      action: "/proc/#{procedure.id}",
      captcha: false,
      fields: [
        %{tag: :hidden, name: "procedure_id", value: procedure.id},
        %{tag: :hidden, strict_name: "nstep", value: "proceed_refus_candidature"},
        %{tag: :textarea, label: "Motif du refus", name: "motif_refus", strict_id: "motif_refus", required: true, explication: "Merci de motiver le refus (ce texte est à l'intention du candidat)"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre"}
      ]
    }
    """
    <h3>Refus de candidature au comité de lecture</h3
    <p>Pour procéder au refus de la candidature, merci de remplir le formulaire ci-dessous.</p>
    #{Html.Form.formate(form)}
    """
  end

  @doc """
  Méthode qui procède vraiment au refus de la candidature de l'user
  candidat pour un motif donné en paramètre.
  """
  def proceed_refus_candidature(procedure) do
    params  = procedure.params
    user    = procedure.user
    form_params = params["f"]
    
    defmaildata = default_mail_data(procedure)
    data_mail = Map.merge(defmaildata, %{
      mail_id:    "user-candidature-refused",
      variables: %{motif: form_params["motif_refus"]}
    })

    send_mail(user, :admin, data_mail)
    log_activity(%{
      owner: user,
      public: false,
      text: "<p>La candidature de #{user.name} (#{user.email}) vient d'être refusée par #{procedure.current_user.name}.</p>",
      creator: procedure.current_user
    })
    delete_procedure(procedure)

    """
    <p>Le refus de la candidature de #{user.name} a été prise en compte.</p>
    """
  end

  @doc """
  Étape d'acceptation de la candidature du candidate

  NB : Cette fonction est appelée aussi bien lorsque le candidat est
  accepté aussi que lorsqu'il a passé le test. S'il y a besoin de 
  faire une distinction, on peut utiliser les procedure.data pour le
  savoir.
  """
  def accepter_candidature(procedure) do
    user = get_owner(procedure)

    # On marque le candidat comme lecteur (2) et comme membre du comité (8)
    User.update_privileges(user, [:reader, :member])
    
    # Données par défaut pour les mails
    defmaildata = default_mail_data(procedure)
    # Variables par défaut pour les mails
    variables = %{
      membre_name: user.name, 
      membre_mail: user.email, 
      une_nouvelle_membre: (user.sexe == "F" && "une nouvelle membre" || "un nouveau membre")
    }

    # Le CANDIDAT reçoit un mail lui annonçant la nouvelle et
    # lui expliquant ce qu'il doit faire maintenant
    # TODO
    # les ADMINISTRATEURS reçoivent tous l'information du nouveau
    # lecture
    mail_data = %{defmaildata | mail_id: "admin-new-membre-comite"}
    mail_data = %{mail_data | variables: variables}
    send_mail(to: :admin, from: :admin, with: mail_data)
    # Les MEMBRES DU COMITÉ reçoivent l'information du nouveau 
    # membre
    mail_data = %{defmaildata | mail_id: "membre-new-membre-comite"}
    mail_data = %{mail_data | variables: variables}
    send_mail(to: :membres, from: :admin, with: mail_data)

    # L'historique reçoit l'information (pour affichage sur la
    # page d'accueil et de suivi du label)
    log_activity(%{
      owner: user,
      text: "<p>#{user.name} vient de rejoindre le comité de lecture du label.</p>",
      creator: procedure.current_user
    })

    """
    <p>Nouveau membre accepté. Vous pouvez voir la <a href="/membres">nouvelle liste des membres</a>.</p>
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
    <p>Je dois demander au candidat de passer le test pour la #{inspect procedure}</p>
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