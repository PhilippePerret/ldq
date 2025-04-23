defmodule LdQ.MyMailer do
  import Swoosh.Email

  @doc """

  @return {Map} une table contenant :
    :subject      Le sujet à évaluer en fonction du destinatire
    :html_body    Le corps heex à évaluer en fonction du destinataire 
  """
  def get_mail(mail_ref, user, params) do
    variables = [user_name: user.name, user_mail: user.email, usexe: user.sexe]
    data = PhilHtml.to_data(
      Path.join(["lib","ldq","procedures",mail_ref]),
      [variables: variables, no_header: true, evaluation: false, no_file: true, headers: [LdQ.Helpers.Feminines]]
    )

    metadata = data.metadata

    body = data.heex
    |> headerize(params)
    |> footerize(params)

    %{
      subject:    subjectize(metadata[:subject]),
      html_body:  body
    }
  end

  defp subjectize(sujet) do
    "[📚 LdQ] #{sujet}"
  end

  # Ajoute l'entête personnalisé
  defp headerize(body, params) do
    "<p>[ENTETE LECTURE DE QUALITÉ]</p>" <> 
    body
  end

  # Ajoute le pied de page voulu
  defp footerize(body, params) do
    body <> "<p>[FOOTER LECTURE DE QUALITE]</p>"
  end
end