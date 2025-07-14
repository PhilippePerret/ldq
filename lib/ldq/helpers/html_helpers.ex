defmodule Html.Helpers do
  @moduledoc """
  Pour aider au formatage HTML.

  @usage

    Le mieux est d'importer ces méthodes :
      import Html.Helpers[, only: ..., except: ...

  @test

  Pour tester ce module, ajouter quelque part :

    import Html.Helpers
    doctest Html.Helpers
  """


  @doc """
  Cf. la méthode dans Html.Form (dans ldq/procedures/form.ex)

  On peut utiliser la version wrap_in/3 pour les cas où la balise
  d'ouverture est vraiment complexe.

  ## Examples

    iex> wrap_in("bonjour", "div")
    "<div>bonjour</div>"

    iex> wrap_in("bonjour", "div.class-css")
    ~s(<div class="class-css">bonjour</div>)

    iex> wrap_in("Bonjour", "div", "dov")
    "<div>Bonjour</dov>"

    iex> wrap_in("Bonjour", ~s(div style="font-size:12pt;"), "div")
    ~s(<div style="font-size:12pt;">Bonjour</div>)

    iex> wrap_in("Bonjour", ~s(div style="font-size:12pt;" class="so"))
    ~s(<div style="font-size:12pt;" class="so">Bonjour</div>)

  @param {String} code Le contenu de la balise
  @param {String} tag La balise (tag) à utiliser
  """
  def wrap_in(code, tag) do
    [tag, class] =
      if String.match?(tag, ~r/\./) do
        [tag, class] = String.split(tag, ".")
        [tag, ~s( class="#{class}")]
      else
        [tag, ""]
      end

    [tag, rest] = 
      if String.match?(tag, ~r/ /) do
        [tag, rest] = String.split(tag, " ", [parts: 2])
        [tag, " #{rest}"]
      else
        [tag, ""]
      end
    ~s(<#{tag}#{class}#{rest}>#{code}</#{tag}>)
  end
  # @param {String} tagOut Balise de fin
  def wrap_in(code, tagIn, tagOut) do
    ~s(<#{tagIn}>#{code}</#{tagOut}>)
  end


  @doc """
  Traitement markdown-like du code transmis.

  ## Paramètres

    - `code` - Un code quelconque mais pouvant contenir du markage Markdown.

  ## Transformations
  
  Pour le moment, la fonction transforme (et dans cet ordre)…

  * les `[titre](lien)` en `<a href="lien">titre</a>`
  * les `***...***` en `<strong><em>...</em></strong>`
  * les `**..**` en `<strong>...</strong>`
  * les `*...*` en `<em>...</em>`

  """
  def md_to_html(code) do
    code
    |> String.replace(~r/\[(.+?)\]\((.+?)\)/, ~s(<a href="\\2">\\1</a>))
    |> String.replace(~r/\*\*\*(.+?)\*\*\*/, ~s(<strong><em>\\1</em></strong>))
    |> String.replace(~r/\*\*(.+?)\*\*/, ~s(<strong>\\1</strong>))
    |> String.replace(~r/\*(.+?)\*/, ~s(<em>\\1</em>))
  end
end