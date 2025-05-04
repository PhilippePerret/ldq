defmodule LdQ.Procedure.CandidatureComite do
  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """
  use LdQWeb.Procedure

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
    %{name: "Test d'admission", fun: :test_admission_comite, admin_required: false, owner_required: true},
    %{name: "Évaluvation du test", fun: :eval_test_admission, admin_required: false, owner_required: true}
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
    update_procedure(procedure, %{next_step: "test_admission_comite"})
    """
    <p>Une demande a été adressée au candidat pour passer le test d'admission. La balle est dans son camp.</p>
    """
  end

  @ans_yesno ["Oui", "Non"]

  @questions_test_admission [
    %{id:  1, question: "Dans un bon style, les adjectifs sont-ils les bienvenus ?", answers: @ans_yesno, right: 1},
    %{id:  2, question: "Un auteur est-il meilleur qu'une autrice ?", answers: @ans_yesno, right: 1},
    %{id:  3, question: "Un roman long n'est pas meilleur qu'un roman court ?", answers: @ans_yesno, right: 0},
    %{id:  4, question: "Parmi ces phrases, laquelle vous semble-t-elle la meilleure ?", answers: [
      "Il approcha de la porte, sortit son épée et frappa six coups.", 
      "Il approcha de la grande et belle porte, sortit son épée lustrée et frappa six grands coups.", 
      "Il approcha de la grande et belle porte, sortit sa grande épée lustrée et frappa six grands coups."], right: 0
    },
    %{id:  5, question: "Pour vous, quelle est la meilleure phrase ?", right: 0, answers: [
      "Délicatement, il lui fit une caresse en pensée. Si elle avait été sincère, elle l'aurait touchée.", 
      "Délicatement, il lui fit, en pensée, une caresse qui, si elle avait été sincère, l'aurait touchée.",
      "Il lui fit, délicatement, en pensée, une caresse qui l'aurait touchée si elle avait été sincère."
    ]},
    %{id:  6, 
      question: "Quelle est la meilleure phrase ?", right: 0, answers: [
        "phrase1", 
        "phrase2",
        "phrase3"
    ]},
    %{id:  7, 
      question: "Quelle est pour vous la collocations la plus naturelle ?", answers: [
      "Ébranler les certitudes", "Bousculer les certitudes", "Remettre en cause les certitudes"], right: 0},
    %{id:  8, 
      question: "Quelle est pour vous la collocations la plus naturelle ?", answers: [
      "Briser ses chaines", "Rompre ses chaines", "Couper ses chaines"], right: 0},
    %{id:  9, question: "Quel est l'idiome le plus courant ?", answers: [
      "idiome 1", "idiome2", "idiome3"], right: 0},
    %{id: 10, question: "L'orthographe n'est pas très importante pour estimer un livre. C'est vrai ?", answers: @ans_yesno, right: 1},
    %{id: 11, question: "La clarté passe-t-elle avant le style ?", answers: @ans_yesno, right: 0},
    %{id: 12, question: "Le style passe-t-il avant la structure ?", answers: @ans_yesno, right: 1},
    %{id: 13, question: "Quelle phrase ne comporte aucune faute d'ortographe ?", right: 0, answers: [
      "Quand elle est venue devant lui, il l'a serrée dans ses bras.",
      "Quand elle est venue devant lui, il la serrait dans ses bras.",
      "Quand elle est venue devant lui, il la pressait contre lui."
    ]},
    %{id: 14, question: "Quelle phrase est bonne ?", right: 0, answers: [
      "Regarde ! comme il est beau, etc.",
      "Regarde! Il est venu avec lui, etc…", 
      "Regarde ! Il est venu, etc…", 
      "Regarde ! Comme il est grand ! Etc…"
    ]},
    %{id: 15, question: "Quelle phrase est valide ?", right: 0, answers: [
      "– Ne ris pas ! lui demanda-t-elle.",
      "–Ne ris pas ! lui demanda-t-elle.",
      "- Ne ris pas ! Lui demanda-t'elle.",
      "– Ne ris pas ! Lui demanda-t-elle.",
      " Ne ris pas! lui demanda-t-elle."
    ]},
    %{id: 16, question: "Quelle est la phrase correcte ?", right: 0, answers: [
      "Comme il approchait de la ville, il aperçut le feu.",
      "Comme il approcha de la ville, il aperçut le feu.",
      "Comme il approchait de la ville, il eut aperçu le feu."
    ]},
    %{id: 17, question: "La répétition de mots améliore le style.", right: 1, answers: @ans_yesno},
    %{id: 18, question: "L'usage des comparaisons en “comme…” (“comme une fusée orpheline”) améliore grandement le style.", right: 1, answers: @ans_yesno},
    %{id: 19, question: "L'usage des pronoms personnels apporte de la confusion.", right: 0, answers: @ans_yesno},
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
    data_questions = get_random_questions_for_tests(15)
    questions_formated = formate_questions(data_questions)

    form = %Html.Form{
      id: "test-candidature",
      method: "POST",
      action: "/proc/#{procedure.id}",
      captcha: false,
      fields: [
        %{tag: :raw, content: questions_formated},
        %{tag: :hidden, strict_name: "nstep", value: "eval_test_admission"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre le test"}
      ]
    }

    # En mode test, on enregistre les données questions choisies
    if Mix.env() == :test do
      path = Path.join(["test","xtmp","test-comite-#{procedure.user.id}"])
      File.write!(path, :erlang.term_to_binary(data_questions))
    end
    
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
    params = procedure.params
    IO.inspect(params, label: "\nParam de eval_test_admission")

    questions_ids = params["questions_ids"] |> Enum.map(fn id -> String.to_integer(id) end)
    
    table_questions = 
      @questions_test_admission
      |> Enum.reduce(%{}, fn dquest, table -> 
        Map.put(table, dquest.id, dquest)
      end)

    questions = 
      questions_ids
      |> Enum.map(fn id -> 
        table_questions[id]
      end)
      # |> IO.inspect(label: "Questions proposées")

    # Tenir compte du temps 
    # data.test_start_time
    # TODO

    report =
      questions
      |> Enum.with_index()
      |> Enum.reduce(%{note: 0, total: 0, rapport: ""}, fn {dquest, index}, report ->
        # Fabrication du rapport pour la question
        qid = "Q#{dquest.id}"
        mark_quest = wrap_in("Question ##{index + 1} : #{dquest.question}", "div.question")
        good_answer = Enum.at(dquest.answers, dquest.right)

        if params[qid] do
          rep = params[qid]
          # IO.inspect(rep, label: "\nRéponse de #{qid}")
          choix = String.split(rep, "-") |> Enum.at(1) |> String.to_integer()
          {new_note, phrase_rapport} =
            if choix == dquest.right do
              # Bonne réponse
              {report.note + 1, ~s[<span class="success bold">+1 pt</span>  — OK (#{good_answer})]}
            else
              # Mauvaise réponse
              if choix == 100 do
                # a répondu "ne sait pas"
                {report.note, ~s[<span class="notice bold">+ 0 pts</span> — Bonne réponse : #{good_answer}.]}
              else
                bad_answer = Enum.at(dquest.answers, choix)
                {report.note - 1, ~s[<span class="error bold">-1 pt</span> — La bonne réponse n'était pas “#{bad_answer}” mais “#{good_answer}”.]}
              end
            end
          Map.merge(report, %{
            note: new_note,
            rapport: report.rapport <> ~s(<div class="qreponse_correction">) <> mark_quest <> wrap_in(phrase_rapport, "div") <> "</div>",
            total: report.total + 1
          })
        else
          # Question sans réponse
          good_answer = Enum.at(dquest.answers, dquest.right)
          Map.merge(report, %{
            total: report.total + 1,
            rapport: report.rapport <> wrap_in("Non répondue : #{dquest.question} Réponses : #{good_answer}", "div.qreponse_correction")
          })
        end
      end)
    # Donner le résultat direct, notamment avec les bonnes réponses.
    # TODO

    # Avertir l'administration avec les résultats
    # TODO

    is_success = report.note / report.total >= 0.7
    main_class = if is_success, do: "success", else: "failure"
    msg_resultat = if is_success do
      "Bravo ! Vous avez passé ce test avec succès, votre candidature va pouvoir être validée !"
    else
      "Désolé, vous n'avez pas le niveau requis pour rejoindre le comité de lecture du label. Nous en sommes désolés pour vous."
    end

    """
    <h3>Résultat du test d'admission</h3>
    <p class="bigger bold center #{main_class}">Votre total est de #{report.note} / #{report.total}.</p>
    <p class="bigger #{main_class}">#{msg_resultat}</p>
    #{report.rapport}
    """
  end

  # =========== FIN DES ÉTAPES ================== #

  # @return les questions pour le test
  # NB: Ce sont des champs pour Html.Form
  defp get_random_questions_for_tests(nombre) do
    get_random_question_for_test(@questions_test_admission, [], 0, nombre)
  end
  def get_random_question_for_test(rest, questions, nombre, expected) when nombre < expected do
    max_id = Enum.count(rest) - 1
    index = Enum.random(0..max_id)
    {dquestion, rest} = List.pop_at(rest, index)
    questions = questions ++ [dquestion]
    get_random_question_for_test(rest, questions, nombre + 1, expected)
  end
  def get_random_question_for_test(rest, questions, n, e), do: questions

  # Formater les questions relevées au hasard
  defp formate_questions(data_questions) do
    data_questions
    |> Enum.map(fn data_question -> 
      formate_question(data_question)
    end)
    |> Enum.join("")
  end
  defp formate_question(data_question) do
    qid = "Q#{data_question.id}"
    question = ~s(<label id="#{qid}-label" class="question">#{data_question.question}</label>)

    # Les boutons radio en fonction du type
    boutons_radio =
      data_question.answers
      |> Enum.with_index()
      |> Enum.shuffle()
      |> Enum.map(fn {answer, index} -> 
        ["rep-#{index}", answer]
      end)
    
    # On ajoute le bouton "Je ne sais pas"
    boutons_radio = boutons_radio ++ [["rep-100", "Je ne sais pas"]]

    style_reponses = 
      boutons_radio |> Enum.reduce("inline", fn [sufid, label], value ->
        if String.length(label) > 14 do
          "block"
        else
          value
        end
      end)
    # Les boutons radio formatés
    boutons_radio =
      boutons_radio
      |> Enum.map(fn [sufid, label] ->
        """
        <span class="reponse #{style_reponses}">
        <input type="radio" id="#{qid}_#{sufid}" name="#{qid}" value="#{sufid}" />
        <label for="#{qid}_#{sufid}">#{label}</label>
        </span>
        """
      end)
      |> Enum.join("")
      |> wrap_in(~s(div class="reponses"), "div")

    hidden_id = ~s(<input type="hidden" name="questions_ids[]" value="#{data_question.id}" />)
    [
      ~s(<div id="#{qid}question" class="Q-container">),
      hidden_id, 
      question,
      boutons_radio,
      "</div>"
    ] |> Enum.join("")
  end


end