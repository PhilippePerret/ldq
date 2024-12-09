defmodule PPMarkdown.Engine do
  @behaviour Phoenix.Template.Engine

  # Ça râle un peu, mais ça passe
  @table_vars Application.get_env(:phoenix_markdown, :table_vars) || %{}
  # Devra être remplacé par la ligne suivante lorsque my_markdown (ou autre meilleur
  # nom sera vraiment une dépendance)
  # @table_vars Application.get_env(:my_markdown, :table_vars)

  # use Phoenix.Component

  def compile(path, name) do

    # Plus tard, on pourra définir des options
    options = %{}

    path
    |> File.read!()
    |> Earmark.as_html!(earmark_options())
    |> handle_smart_tags(path, name)
    |> mmd_transformations(options)
    |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)
  end

  defp mmd_transformations(code, _options) do
    code 
    |> transforme_paths()
    |> transforme_vars()
  end

  defp transforme_paths(code) do
    Regex.replace(~r"path\((.*)\)"U, code, "<path>\\1</path>")
    # |> IO.inspect(label: "après transformation de path")
  end

  
  # Méthode qui traite tous les `var(<variable id>)' dans les codes markdown
  #
  # Ces variables doivent être définies dans une table implémentée dans config/config.ex
  # de l'application, définie par :
  #
  #   config :my_markdown, :table_vars, %{var: val, var: val, ...}
  #
  #   (pour le moment, comme 'my_markdonw' n'est pas encore définitif, on passe
  #    par config :phoenix_markdown, :table_vars, %{...})
  defp transforme_vars(code) do
    code = Regex.replace(~r/var\((.*)\)/U, code, fn _, varid -> get_in_table_vars(varid) end)
    code
  end
  defp get_in_table_vars(var_id) do
    @table_vars[String.to_atom(var_id)]
  end

  # defp on_load() to
  #   if Module.has_attribute?(__MODULE__, :table_vars) do
  # end

  # 
  # ============ RÉCUPÉRÉ DE PhoenixMarkdown ================
  #
  defp earmark_options() do
    case Application.get_env(:phoenix_markdown, :earmark) do
    %Earmark.Options{} = opts ->
      opts
    %{} = opts ->
      Kernel.struct!(Earmark.Options, opts)
    _ ->
      %Earmark.Options{}
    end
  end

  # --------------------------------------------------------
  defp handle_smart_tags(markdown, path, name) do
    restore =
      case Application.get_env(:phoenix_markdown, :server_tags) do
        :all -> true
        {:only, opt} -> only?(opt, path, name)
        [{:only, opt}] -> only?(opt, path, name)
        {:except, opt} -> except?(opt, path, name)
        [{:except, opt}] -> except?(opt, path, name)
        _ -> false
      end

    do_restore_smart_tags(markdown, restore)
  end

  # --------------------------------------------------------
  defp do_restore_smart_tags(markdown, true) do
    smart_tag = ~r/&lt;%.*?%&gt;/
    markdown = Regex.replace(smart_tag, markdown, &HtmlEntities.decode/1)

    uri_smart_tag = ~r/%3C(%25)+.*?%25%3E/
    Regex.replace(uri_smart_tag, markdown, &URI.decode/1)
  end

  defp do_restore_smart_tags(markdown, _), do: markdown

  # --------------------------------------------------------
  defp only?(opt, path, name) when is_bitstring(opt) do
    case opt == name do
    true -> true
    false ->
      paths = Path.wildcard(opt)
      Enum.member?(paths, path)
    end
  end

  defp only?(opts, path, name) when is_list(opts) do
    Enum.any?(opts, &only?(&1, path, name))
  end

  # sadly there is no is_regex guard...
  defp only?(regex, path, _) do
    if Regex.regex?(regex) do
      String.match?(path, regex)
    else
      raise ArgumentError,
            "Invalid parameter to PhoenixMarkdown only: configuration #{inspect(regex)}"
    end
  end

  # --------------------------------------------------------
  defp except?(opt, path, name) when is_bitstring(opt) do
    case opt == name do
      true -> false
      false ->
        paths = Path.wildcard(opt)
        !Enum.member?(paths, path)
    end
  end

  defp except?(opts, path, name) when is_list(opts) do
    Enum.all?(opts, &except?(&1, path, name))
  end

  # sadly there is no is_regex guard...
  defp except?(regex, path, _) do
    if Regex.regex?(regex) do
      !String.match?(path, regex)
    else
      raise ArgumentError,
            "Invalid parameter to PhoenixMarkdown except: configuration #{inspect(regex)}"
    end
  end
  
end