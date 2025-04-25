defmodule Phil.File do
  @moduledoc """

  import Phil.File, only: [<fonction>: <arity>, ...]
  """

  def file_mtime(path) do
    if File.exists?(path) do
      File.stat!(path).mtime 
      |> NaiveDateTime.from_erl!()
      # |> IO.inspect(label: "M-Time #{path}")
    else
      nil
    end
  end
end