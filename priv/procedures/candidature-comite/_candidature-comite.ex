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
    %{name: "Test d'admission", fun: :test_admission_comite, admin_required: false, owner_required: true}
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

    # L'historique reçoit l'information (pour affichage sur la
    # page d'accueil et de suivi du label)
    log_activity(%{
      owner: user,
      public: false,
      text: "<p>Refus de la candidature de #{user.name} au motif de : #{form_params["motif_refus"]}</p>",
      creator: procedure.current_user
    })

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
    send_mail(to: user.mail, from: :admins, with: params)
  end

  def soumettre_a_test(procedure) do
    # Envoi du mail au candidat
    defmaildata = default_mail_data(procedure)
    data_mail = Map.merge(defmaildata, %{
      mail_id: "candidat-test-required",
      variables: %{test_url: proc_url(procedure, title: "Passer le test")}
    })
    send_mail(to: procedure.user, from: :admin, with: data_mail)
    # Marquage de procédure suivante
    procedure = update_procedure(procedure, %{next_step: "test_admission_comite"})
    """
    <p>Une demande a été adressée au candidat pour passer le test d'admission. La balle est dans son camp.</p>
    """
  end

  @questions_test_admission [
    %{type: :yes_no,  id:  1, question: "Dans un bon style, les adjectifs sont-ils les bienvenus ?", right: "yes"},
    %{type: :yes_no,  id:  2, question: "Un auteur est-il meilleur qu'une autrice ?", right: "false"},
    %{type: :yes_no,  id:  3, question: "Un roman long est-il meilleur qu'un roman court ?", right: "false"},
    %{type: :unchoix, id:  4, question: "Parmi ces phrases, laquelle vous semble-t-elle la meilleure ?", answers: ["phrase1", "phrase2","phrase3"], right: 1},
    %{type: :unchoix, id:  5, question: "Pour vous, quelle est la meilleure phrase ?", answers: ["phrase1", "phrase2","phrase3"], right: 0},
    %{type: :unchoix, id:  6, 
      question: "Quelle est la meilleure phrase ?", answers: [
        "phrase1", "phrase2","phrase3"], right: 2},
    %{type: :unchoix, id:  7, 
      question: "Quelle est pour vous la collocations la plus naturelle ?", answers: [
      "Ébranler les certitudes", "Bousculer les certitudes", "Remettre en cause les certitudes"], right: 0},
    %{type: :unchoix, id:  8, 
      question: "Quelle est pour vous la collocations la plus naturelle ?", answers: [
      "idiome 1", "idiome2", "idiome3"], right: 0},
    %{type: :unchoix, id:  9, question: "Quel est l'idiome le plus courant ?", answers: ["idiome 1", "idiome2", "idiome3"], right: 1},
    %{type: :yes_no,  id: 10, question: "L'orthographe n'est pas très importante pour estimer un livre", right: "false"},
    %{type: :yes_no,  id: 11, question: "La clarté passe avant le style", right: "true"},
    %{type: :yes_no,  id: 12, question: "Le style passe avant la structure", right: "false"},
    %{type: :unchoix, id: 13, question: "Quelle phrase ne comporte aucune faute d'ortographe ?", right: 0, answers: [
      "Elle vint devant lui. Il l'a serrée dans ses bras.",
      "Elle vint devant lui. Il la serrait dans ses bras.",
      "Elle vin devant lui. Il la pressait contre lui."
    ]},
    %{type: :unchoix, id: 14, question: "Quelle phrase est bonne ?", right: 0, answers: [
      "Regarde ! comme il est venu etc.",
      "Regarde! Il est venu etc…", 
      "Regarde ! Il est venu etc…", 
      "Regarde ! Comme il est grand ! Etc…"
    ]},
    %{type: :unchoix, id: 15, question: "Quelle phrase est juste ?", right: 0, answers: [
      "– Ne ris pas ! lui demanda-t-elle.",
      "–Ne ris pas ! lui demanda-t'elle",
      " Ne ris pas ! Lui demanda-t'elle",
      "– Ne ris pas ! Lui demanda-t-elle.",
      " Ne ris pas! lui demanda-t-elle"
    ]}
  ]

  @doc """
  Grosse fonction étape qui permet au candidat de passer le test
  d'admission au comité.
  La page présente le test est permet de le remplir et de le soumet-
  tre comme un formulaire "normal"
  """
  def test_admission_comite(procedure) do
    params = procedure.params

    # On inscrit le temps de départ, sauf s'il a déjà été déterminé
    # par une autre venue
    procedure = 
      if Map.get(procedure.data, :test_start_time) do
        procedure # on ne change pas le temps de départ déjà enregistré
      else
        data = procedure.data
        data = Map.put(data, :test_start_time, NaiveDateTime.utc_now())
        update_procedure(procedure, %{data: data})
      end


    # On récupère les champs de questions au hasard
    random_questions = get_random_questions_for_tests(10)
    form = %Html.Form{
      id: "test-candidature",
      method: "POST",
      action: "/proc/#{procedure.id}",
      captcha: false,
      fields: [
        %{tag: :raw, content: random_questions},
        %{tag: :hidden, strict_name: "nstep", value: "eval_test_admission"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre le test"}
      ]
    }
    
    """
    <h3>Test d'admission au comité de lecture</h3>
    <p>Merci de remplir ce test et de le soumettre.</p>
    <p class="warning">Attention : le principe d'incitation à l'honnêteté est appliqué dans ce <nowrap>test :</nowrap> une mauvaise réponse retire un point tandis que la réponse « je ne sais pas » n'en ôte pas.</p>
    <section class="quiz">
      #{Html.Form.formate(form)}
    </section>
    """
  end

    @doc """
  Évaluation du test d'admission
  """
  def eval_test_admission(procedure) do
    "<p class=error>Je dois apprendre à évaluer le test d'admission</p>"
  end


  # @return les questions pour le test
  # NB: Ce sont des champs pour Html.Form
  defp get_random_questions_for_tests(nombre) do
    get_random_question_for_test(@questions_test_admission, "", 0, nombre)
  end
  def get_random_question_for_test(rest, questions, nombre, expected) when nombre < expected do
    max_id = Enum.count(rest) - 1
    index = Enum.random(0..max_id)
    {dquestion, rest} = List.pop_at(rest, index)
    questions = questions <> formate_question(dquestion)
    get_random_question_for_test(rest, questions, nombre + 1, expected)
  end
  def get_random_question_for_test(rest, questions, n, e), do: questions

  def formate_question(data_question) do
    qid = "Q#{data_question.id}-"
    question = ~s(<label id="#{qid}label" class="question">#{data_question.question}</label>)

    # Les boutons radio en fonction du type
    boutons_radio =
      case data_question.type do
      :yes_no ->
        [~w(yes Oui), ~w(no Non)]
      :unchoix ->
        data_question.answers
        |> Enum.shuffle()
        |> Enum.with_index()
        |> Enum.map(fn {answer, index} -> 
          ["rep-#{index}", answer]
        end)
      end
    
    # On ajoute le bouton "Je ne sais pas"
    boutons_radio = boutons_radio ++ [["cpas", "Je ne sais pas"]]

    # Les boutons radio formatés
    boutons_radio =
      boutons_radio
      |> Enum.map(fn [sufid, label] ->
        """
        <span class="reponse">
        <input type="radio" id="#{qid}#{sufid}" name="#{qid}#{sufid}" />
        <label for="#{qid}#{sufid}">#{label}</label>
        </span>
        """
      end)
      |> Enum.join("")
      |> wrap_in(~s(div class="reponses #{data_question.type}"), "div")

    ~s(<div id="#{qid}question" class="Q-container">) <> question <> boutons_radio <> "</div>"
  end


end