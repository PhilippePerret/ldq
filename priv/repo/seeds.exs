# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LdQ.Repo.insert!(%LdQ.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


alias LdQ.Repo
alias LdQ.Comptes.User
alias LdQ.Proc

import Ecto.Query

hashed_password = Bcrypt.hash_pwd_salt("xadcaX-huvdo9-xidkun")

email_phil = "philippe.perret@yahoo.fr"

if (Mix.env() == :dev) and is_nil(Repo.one(from(u in User, where: u.email == ^email_phil))) do
  Repo.insert!(%User{
    name: "Phil", 
    email: email_phil,
    hashed_password: hashed_password,
    privileges: 64
  })
end

# *======== Définition des procédures ===============*

defmodule Seeds do

  def remove_proc_if_exists(short_name) do
    query = from p in Proc.AbsProc, where: p.short_name == ^short_name
    if Repo.one(query), do: Repo.delete_all(query)
  end

  def remove_step_if_exists(short_name) do
    query = from p in Proc.AbsStep, where: p.short_name == ^short_name
    if Repo.one(query), do: Repo.delete_all(query)
  end
end

# Détruire cette procédure doit détruire toutes les étapes qui lui appartiennent
Seeds.remove_proc_if_exists("soumission-lecteur")
steps = []

absproc = Repo.insert!(%Proc.AbsProc{
  name: "Soumission de la candidature pour être lecteur du comité",
  short_name: "soumission-lecteur",
  owner_type: "user",
  steps: [],
  short_description: "Cette procédure permet à un user inscrit sur le label de proposer sa candidature pour être lecteur ou lectrice.",
  description: """
  Procédure de soumission d'une candidature au comité de lecture pour être lecteur ou lectrice.
  L'user qui fait la demande doit être inscrit et passe par un certain nombre d'étape avant de voir sa candidature être acceptée, ou pas.
  """
})

# Seeds.remove_step_if_exists("soumission-main-formulaire")
step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Soumission du formulaire",
  short_name: "soumission-main-formulaire",
  short_description: "Le candidat soumet le formulaire de sa demande.",
  description: nil,
  data: nil,
  fonction: nil
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Envoi mail confirmation soumission",
  short_name: "mail-conf-submit-candidate",
  short_description: "Envoi du mail qui confirme au candidat que sa candidature a bien été soumise.",
  data: %{mail: :default, destinataire: :owner},
  fonction: "send_mail"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Notification à l'administration",
  short_name: "notify-candidature",
  short_description: "Notification à l'administration de la nouvelle candidature à gérer",
  description: "Elle ne disparaitra que lorsque la candidature sera gérée.",
  data: %{notice: :default, destinataire: :administration},
  fonction: "notify"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Envoi mail annonce soumission aux administrateurs",
  short_name: "mail-notify-submit-admins",
  short_description: "Envoi d'un message mail aux administrateur pour les informer de la nouvelle candidature",
  data: %{mail: :default, destinataire: :admins},
  fonction: "send_mail"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Candidature refusée",
  short_name: "candidature-refused",
  short_description: "La candidature du membre est refusée pour un motif qui lui sera spécifié.",
  data: %{mail: :default, destinataire: :owner, ask_for: :raison},
  fonction: "send_mail",
  last: true
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Candidature directe acceptée",
  short_name: "candidature-directe-accepted",
  short_description: "La candidature du membre est acceptée directement, sans tests.",
  data: %{mail: :default, destinataire: :owner},
  fonction: "procedure_acceptation_membre_comite",
  last: true
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Demande de passer le test d'adminission",
  short_name: "test-candidature-membre-required",
  short_description: "Procédure de demande faite au candidat pour qu'il passe le test.",
  data: %{mail: :default, destinataire: :owner},
  fonction: "send_mail"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Test d'adminission au comité de lecture",
  short_name: "test-candidature-membre-submited",
  short_description: "Quand le membre soumet son test d'adminission au comité de lecture",
  data: nil,
  fonction: "soumission_test_adminission_membre_comite"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Mail de notification aux administrateurs",
  short_name: "mail-admins-on-test-admit-member-comite",
  short_description: "Mail envoyé aux administrateur lorsqu'un candidat passe le test d'admission au comité de lecture.",
  data: %{mail: :default, destinataire: :admins},
  fonction: "send_mail"
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Échec au test d'adminission au comité de lecture",
  short_name: "failure-test-admit-membre-comite",
  short_description: "En cas d'échec au test d'adminission du comité de lecture",
  data: nil,
  fonction: "on_failure_test_admission_membre_comite",
  last: true
})
steps = steps ++ [step.short_name]

step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Réussite au test d'adminission au comité de lecture",
  short_name: "success-test-admit-membre-comite",
  short_description: "En cas de réussite au test d'adminission comme mebre au comité de lecture",
  data: nil,
  fonction: "on_success_test_admission_membre_comite"
})
steps = steps ++ [step.short_name]
  
step = Repo.insert!(%Proc.AbsStep{
  abs_proc_id: absproc.id,
  name: "Acceptation au comité de lecture après test",
  short_name: "acceptation-membre-comite-after-test",
  short_description: "Lorsque le candidat est accepté comme membre du comité de lecture.",
  data: %{mail: :default, destinataire: :owner},
  fonction: "procedure_acceptation_membre_comite",
  last: true
})
steps = steps ++ [step.short_name]

query = from(p in Proc.AbsProc, where: p.id == ^absproc.id)
|> Repo.update_all(set: [steps: steps])