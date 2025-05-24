defmodule LdQ.Error do

  defexception [:code, :msg, :data, :file, :line]

  def new(err_msg, err_code \\ nil, data \\ nil, file \\ nil, line \\ nil) when is_atom(err_code) and is_binary(err_msg) do
    %__MODULE__{code: err_code, msg: err_msg, file: file, line: line}
  end

  @doc """
  Produire une erreur par :

    raise(LdQ.Error, code: :system, msg: "Une erreur est survenue", file: __FILE__, line: __LINE__)
  
  @param {Keyword} kw_error Table contenant les paramètres de l'erreur
  """
  @impl true
  def exception(kw_err) do
    new(kw_err[:msg], kw_err[:code], kw_err[:data], kw_err[:file], kw_err[:line])
  end

  @doc """
  Retourne l'erreur formatée
  """
  @impl true
  def message(err, params \\ %{admin: false}) do
    segs = []
    
    segs = if err.code do
      segs ++ ["[code :#{err.code}]"]
    else segs end
    
    segs = segs ++ [err.msg]
    
    segs = if err.data do
      segs ++ ["avec les données #{inspect err.data}"]
    else segs end

    segs = if params.admin do
      if is_nil(err.file) do segs else
        segs ++ ["(#{err.file}:#{err.line})"]
      end
    else segs end
  
    Enum.join(segs, " ")
  end

end