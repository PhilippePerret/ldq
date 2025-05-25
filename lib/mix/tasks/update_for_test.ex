defmodule Mix.Tasks.Ecto.UpdateForTest do
  use Mix.Task

  @shortdoc "Synchronise la base en mode test et nettoie les photographies"

  def run(_) do
    IO.puts IO.ANSI.green() <> """
    --- Synchronisation de la table en mode test ---

    Cette opération, en plus de resetter la base de données en mode
    test comme la commande ecto.reset :
      - remet les pages fixes dans les tables adéquates
    """
    IO.write "  - et surtout "
    IO.write IO.ANSI.red() <> "DÉTRUIS TOUTES LES PHOTOGRAPHIES"
    IO.puts IO.ANSI.green() <> "utilisées dans" 
    IO.puts """
        les tests qui permettent de repartir à un point donné. C'est
        normal puisque les nouvelles tables ont changées et les anciennes
        écraseraient alors les nouvelles.
    
    Il faudra donc les refaire une par une. Pour ce faire, il suffit de 
    lancer tous les tests et de voir les signalements d'erreur de photo-
    graphie manquante.

    """ <> IO.ANSI.reset()
    res = IO.getn(IO.ANSI.yellow() <> "Voulez-vous donc vraiment procéder à cette opération ? (oui : y/o, non : autre touche)" <> IO.ANSI.reset())
    IO.inspect(res, labe: "\nRÉPONSE")
    if res == "o" || res == "y" do
      # Resetter la base
      IO.write "- Reset de la base…"
      System.cmd("mix", ["ecto.reset"], env: [{"MIX_ENV", "test"}] )
      IO.puts " OK"
      # Synchroniser les pages
      IO.write "- Synchronisation des pages"
      Mix.LdQMethods.sync_pages()
      IO.puts " OK"
      # Détruire les photographies pour les tests et refaire le 
      # dossier
      IO.write "- Destruction des photographies tests"
      folder_path = Path.join(["test","xbdd_dumps"])
      File.rm_rf(folder_path)
      File.mkdir(folder_path)
      IO.puts " OK"
      IO.puts IO.ANSI.green() <> "\nOpération terminée" <> IO.ANSI.reset()
    end
  end

end
defmodule Mix.Tasks.Sync.Pages do
  use Mix.Task
  # import Ecto.Query

  @shortdoc "Synchronise pages et page_locales de ldq_dev vers ldq_test"

  def run(_) do
    Mix.LdQMethods.sync_pages()
  end

end

defmodule Mix.LdQMethods do
  def sync_pages do
    System.cmd("psql", ["-d", "ldq_test", "-c", "DROP TABLE pages, page_locales;"])
    System.cmd("sh", ["-c", "pg_dump -d ldq_dev -t pages | psql ldq_test"])
    System.cmd("sh", ["-c", "pg_dump -d ldq_dev -t page_locales | psql ldq_test"])
  end
end