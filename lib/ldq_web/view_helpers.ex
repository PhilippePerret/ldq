defmodule LdQWeb.ViewHelpers do

  use Phoenix.Component

  # Pour les utiliser dans les pages Markdown, il faut mettre :
  #   <%= <function>(nil) %>

  def tiret(assigns) do
    ~H'<font face="serif">-</font>'
  end

  def ldq_label(assigns) do
    ~H'<span class="label">Lecture de Qualité</span>'
  end
  def label_ldq(assigns), do: ldq_label(assigns)

  def membres(assigns) do
    case assigns[:fem] do
      true -> ~H'membres<font face="serif">-</font>lectrices/lecteurs'
      _ -> ~H'membres<font face="serif">-</font>lecteurs'
    end
    # ~H'membres<font face="serif">-</font>lecteurs'
  end

  def membre(assigns) do
    case assigns[:fem] do
      true -> ~H'membre<font face="serif">-</font>lectrice/lecteur'
      _ -> ~H'membre<font face="serif">-</font>lecteur'
    end
  end

  # def lien_credibilite(assigns) do
  #   lien_mot("crédit", "credit", assigns)
  # end

  # def lien_parrain(assigns) do
  #   lien_mot("parrain", nil, assigns)
  # end


  # defp lien_mot(mot, id, assigns) do
  #   id = if id == nil, do: mot, else: id
  #   lien = "/mot/#{id}"
  #   ~H'<a href={lien}><%= mot %></a>'
  # end

  def lien_faire_connaitre(ancre \\ nil) do
    "<a href=\"/apropos/faire_connaitre\?anchor=#{ancre}\">faire connaitre ce label</a>"
  end

end
