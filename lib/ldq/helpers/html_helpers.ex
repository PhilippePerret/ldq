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
  Cf. la méthode dans Html.Form

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

end