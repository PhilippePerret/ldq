defmodule LdQWeb.SpecPageHTML do
  use LdQWeb, :html

  embed_templates "spec_page_html/*"


  attr :logs, LdQ.Site.Log, required: true
  def last_activities(assigns) do
    logs_string = Enum.map(assigns.logs, &(&1.text)) |> Enum.join("\n")
    assigns = assigns
    |> assign(logs_string, logs_string)
    ~H"""
    <%= logs_string %>
    """
  end
end