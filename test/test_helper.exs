ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(LdQ.Repo, :manual)
Application.put_env(:wallaby, :base_url, LdQWeb.Endpoint.url())

Code.require_file("support/feature_case.ex", __DIR__)

defmodule TestHelpers do

  def w(str, color \\ :white) do
    params = case color do
      :white  -> [IO.ANSI.white(), str, IO.ANSI.reset()]
      :red    -> [IO.ANSI.red(), str, IO.ANSI.reset()]
      :blue   -> [IO.ANSI.blue(), str, IO.ANSI.reset()]
      :gris   -> IO.ANSI.format(["color:200,200,200", str, :reset])
    end
    IO.puts params
  end

end