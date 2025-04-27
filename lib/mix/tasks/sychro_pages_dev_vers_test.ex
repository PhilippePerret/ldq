defmodule Mix.Tasks.Sync.Pages do
  use Mix.Task
  # import Ecto.Query

  @shortdoc "Synchronise pages et page_locales de ldq_dev vers ldq_test"

  def run(_) do
    System.cmd("psql", ["-d", "ldq_test", "-c", "DROP TABLE pages, page_locales;"])
    System.cmd("sh", ["-c", "pg_dump -d ldq_dev -t pages | psql ldq_test"])
    System.cmd("sh", ["-c", "pg_dump -d ldq_dev -t page_locales | psql ldq_test"])
  end

end