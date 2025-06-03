defmodule Phil.UtilsTest do
  @moduledoc """
  Pour tester mes utilitaires extensions des structures
  d'Elixir (Phil.Map, Phil.Keyword, etc.)
  Cf. le fichier lib/usefull/phil_utils.ex
  
  """
  use ExUnit.Case

  doctest Phil.Map


  describe "Fonction Phil.PFile.last_lines" do

    test "permet de lire les x dernières lignes d'un fichier" do
      path = Path.join(["test","assets","files","faux.log"])
      File.exists?(path) && File.rm(path)
      {:ok, rf} = File.open(path, [:append])
      line = "Une première ligne dans le fichier log."
      :file.write(rf, line)
      :file.close(rf)
      # --- Test ---
      {:ok, lasts} = Phil.PFile.last_lines(path, 10)
      # --- Vérification ---
      assert(Enum.count(lasts) == 1)
      assert(Enum.at(lasts, 0) == line)
      # === On poursuit en écrivant d'autres lignes ===
      {:ok, rf} = File.open(path, [:append])
      (1..1000) |> Enum.each(fn x -> :file.write(rf, "La ligne numéro #{x}.\n") end)
      :file.close(rf)
      # --- Test ---
      {:ok, lasts} = Phil.PFile.last_lines(path, 10)
      # --- Vérifications ---
      assert(Enum.count(lasts) == 10)
      assert(Enum.at(lasts, 9) == "La ligne numéro 1000.")
      assert(Enum.at(lasts, 0) == "La ligne numéro 991.")
    end

    test "avec un !, raise si le fichier n'existe pas" do
      path = Path.join(["test","assets","files","faux.log"])
      File.exists?(path) && File.rm(path)
      assert_raise(MatchError, fn ->
        Phil.PFile.last_lines!(path, 2)
      end)
    end

    test "sans !, retourne :error si le fichier n'existe pas" do
      path = Path.join(["test","assets","files","faux.log"])
      File.exists?(path) && File.rm(path)
      # --- Test ---
      res = Phil.PFile.last_lines(path, 2)
      # --- Vérifications ---
      assert(elem(res, 0) == :error)
    end

    @tag :pending
    test "ne retourne pas le bon nombre de lignes avec une longueur de ligne trop courte" do

    end

  end #/describe Phil.PFile.last_lines

end