defmodule LdQ.Mailer do
  use Swoosh.Mailer, otp_app: :ldq

  import Swoosh.Email

  def send_test_email() do
    new()
    |> from("phil@atelier-icare.net")
    |> to("philippe.perret@yahoo.fr")
    |> subject("Test de l'envoi d'email")
    |> text_body("Ceci est un test pour vérifier que l'envoi fonctionne.")
    |> deliver()
    IO.puts "J'ai bien envoyé le mail"
  end

end
