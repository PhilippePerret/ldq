defmodule Mix.Tasks.Test.Feature do
  use Mix.Task

  @shortdoc "Permet de lancer des tests d'intégration en les choisissant"

  def run(_) do
    IO.puts [IO.ANSI.blue(), 
    "Cette commande ne lance que les derniers tests\n",
    "demandés. Pour les choir, copier-coller et jouer\n",
    " la commande : \n", IO.ANSI.yellow(), "ruby ./test/feature/__test_runner__.rb",
    "\n"
    IO.ANSI.reset()]

    System.shell("ruby ./test/feature/__test_runner__.rb -s", into: IO.stream())
  end

end