defmodule Mix.Tasks.Test.Feature do
  use Mix.Task

  @shortdoc "Permet de lancer des tests d'intégration en les choisissant"

  def run(_) do
    IO.puts [IO.ANSI.blue(), "Pour lancer les tests d’intégration,\nCopie-colle et joue la commande : \n", IO.ANSI.yellow(), "ruby ./test/feature/__test_runner__.rb", IO.ANSI.reset()]
  end

end