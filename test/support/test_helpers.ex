defmodule TestHelpers do

  def w(str, color \\ :white) do
    params = case color do
      :white  -> [IO.ANSI.white(), str, IO.ANSI.reset()]
      :red    -> [IO.ANSI.red(), str, IO.ANSI.reset()]
      :blue   -> [IO.ANSI.blue(), str, IO.ANSI.reset()]
      :grey   -> IO.ANSI.format(["color:200,200,200", str, :reset])
    end
    IO.puts params
  end

  @doc """
  Pour pauser dans un pipe
  Note : hors d'un pipe, mettre nil en premier argument
  """
  def pause(traversor, quantite, unit \\ :seconde) do
    ms = case unit do
      :minute   -> quantite * 60
      :seconde  -> quantite
    end
    Process.sleep(ms * 1000)

    traversor
  end

end
