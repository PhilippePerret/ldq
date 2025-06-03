defmodule LdQ.TriggerTest do
  use LdQ.DataCase

  import FeaturePublicMethods

  alias LdQ.Core.Trigger


  describe "Méthode pose_trigger" do

    test "permet de poser un trigger (de l'enregistrer)" do
      # --- Préparation ---
      test_point = ilya(2, :second)
      book = make_book()
      admin = make_admin()
      procedure = make_procedure(proc_dim: "evaluation-livre", owner_type: "book", owner_id: book.id)
      # --- Test --- 
      Trigger.pose_trigger("evaluation-book", %{book_id: book.id, procedure_id: procedure.id}, [marked_by: admin.id])
      # --- Vérification ---
      assert_trigger(after: test_point, type: "evaluation-book", data: %{book_id: book.id}, debug: true)
      # Une ligne de journal a été enregistrée
      assert_trigger_log(after: test_point, content: ["evaluation-book", book.id])
    end

    test "raise une erreur si le type de trigger n'existe pas" do
      assert_raise(ArgumentError, fn ->
        Trigger.pose_trigger("mauvaise-type-de-trigger")
      end)
    end

    test "raise une erreur si les informations requises ne sont pas données" do
      assert_raise(ArgumentError, fn -> 
        Trigger.pose_trigger("evaluation-book", %{})
      end)
    end

    test "raise une erreur si une des informations requises n'est pas donnée" do
      # --- Préparation ---
      admin = make_admin()
      book  = make_book()
      # --- test ---
      assert_raise(ArgumentError, fn ->
        Trigger.pose_trigger("evaluation-book", %{book_id: book.id}, [marked_by: admin.id])
      end)
    end

    test "raise une erreur si une option manque" do
      # --- Préparation ---
      book  = make_book()
      procedure = make_procedure(proc_dim: "evaluation-livre", owner_type: "book", owner_id: book.id)
      # --- test ---
      assert_raise(ArgumentError, fn ->
        Trigger.pose_trigger("evaluation-book", %{book_id: book.id, procedure_id: procedure.id})
      end)
      # --- Vérification ---
      # N'ajoute pas de ligne de log
      # TODO
    end

    test "raise si un trigger de même scope a déjà été enregistré" do
      # --- Préparation ---
      test_point = ilya(2, :second)
      book = make_book()
      admin = make_admin()
      procedure = make_procedure(proc_dim: "evaluation-livre", owner_type: "book", owner_id: book.id)
      Trigger.pose_trigger("evaluation-book", %{book_id: book.id, procedure_id: procedure.id}, [marked_by: admin.id])
      assert_trigger(after: test_point, type: "evaluation-book", data: %{book_id: book.id}, debug: true)
      # --- Test --- 
      assert_raise(Ecto.InvalidChangesetError, fn ->
        Trigger.pose_trigger("evaluation-book", %{book_id: book.id, procedure_id: procedure.id}, [marked_by: admin.id])
      end)
    end

  end #/describe #pose_trigger
end