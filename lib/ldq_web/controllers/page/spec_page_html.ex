defmodule LdQWeb.SpecPageHTML do
  use LdQWeb, :html

  embed_templates "spec_page_html/*"

  attr :logs, :list, required: true

  def last_activities(assigns) do
    logs_string = Enum.map(assigns.logs, &(&1.text)) |> Enum.join("\n")
    assigns = assigns
    |> assign(logs_string, logs_string)
    ~H"""
    <h4>Dernières activités</h4>
    <%= raw logs_string %>
    """
  end



end