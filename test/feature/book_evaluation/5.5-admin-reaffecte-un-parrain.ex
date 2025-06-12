Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsAffecteAutreParrainage do

  use LdQWeb.FeatureCase, async: false
  import TestHelpers, only: [bddshot: 1, bddshot: 2, pause: 2]
  import FeaturePublicMethods #, except: [now: 0]
  import BookEvaluationMethods

  test "L'administrateur affect un autre parrain au livre" do
    # 
    # - PHOTOGRAPHIE -
    # Ce test produit la photographie "evaluation-book/5.5-reaffection-parratin"
    %{procedure: procedure} = bddshot("evaluation-book/5-membre-college1-choisit-livre")
    
    book = book_of_proc(procedure)
    admin = get_admin()

    # On prend un membre du collège 3 pour le désigner comme parrain
    membre = get_membre_with_session(min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_three) + 1)
    credit_before = membre.credit

    # - Test -
    # Sur la fiche du livre, un administrateur doit trouver un bouton
    # lui permettant d'affecter le parrain.
    # TODO

    # - Vérifications -

    # Le livre doit être affecté au parrain
    book = book_of_proc(procedure)
    assert(book.parrain_id == membre.id, "Le parrain du livre devrait avoir été déterminé.")

    # Le parrain doit avoir reçu un mail pour l'avertir
    # TODO
    
    # Le parrain doit avoir le bon nombre de crédit
    membre = get_user(membre.id)
    points_per_parrainage = LdQ.Evaluation.CreditCalculator.points_for(:parrainage)
    new_credit = credit_before + points_per_parrainage
    assert(membre.credit == new_credit, "Le parrain #{membre.id} devrait avoir un nouveau crédit de #{new_credit}. Il a #{membre.credit} (avant affectation livre : #{credit_before}).")

    bddshot("evaluation-book/5.5-reaffection-parratin", %{
      procedure: procedure
    })
  end


end