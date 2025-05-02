defmodule Html.Form do
  @moduledoc """
  Gestion des formulaires, quand on n'a pas envie des composants HEX

  Html.Form.formate(%Html.Form{
    id:     {String}
    prefix: {String} # "f" par défaut
    method: {String}
    action: {String} POST par défaut
    captcha: {Boolean} Si True, on ajoute un champ captcha
    fields: [
      %{tag: , type: , name: , id: , value: , explication: , required: }
      # Pour un name strict (sinon il deviendra "f[name]")
      %{tag: , strict_name: , id: ...}
      # Pour un identifiant strict (sinon il deviendra "<prefix>[id]")
      %{tag: , strict_id: }
    ]
    buttons: [
      %{type: :submit/:button, name: }
    ]
  })

  Pour vérifier le captcha :

    Html.Form.captcha_valid?(form_data)
  """
  defstruct [
    sujet: nil, # Map du sujet dans lequel il faut prendre les données
    id: nil,
    prefix: "f",
    method: nil,
    action: "POST",
    fields: [],
    buttons: [],
    captcha: false
  ]

  @doc """
  Formate et retourne le code pour le formulaire de données +data+
  """
  def formate(%__MODULE__{} = data, _params \\ %{}) do

    data = 
    if data.captcha do
      %{data | fields: data.fields ++ [%{tag: :captcha}]}
    else data end
    data = 
      if data.prefix do
        data
      else
        %{data | prefix: "f"}
      end

    lines = [~s(<form id="#{data.id}" class="philform" method="#{data.method}" action="#{data.action}">)]
    lines = lines ++ [token_field()]
    lines = lines ++ (
      data.fields
      |> Enum.map(fn dfield -> 
        defaultize_field(Map.merge(dfield, %{prefix: data.prefix, original_name: dfield[:name]||dfield[:strict_name]}))
      end)
      |> Enum.map(fn dfield ->
        (label(dfield) <> explication(dfield) <> build_field(dfield.tag, dfield))
        |> wrap(dfield)
      end))
    lines = lines ++ [~s(<div class="buttons">)]
    lines = lines ++ (data.buttons
    |> Enum.map(fn dbutton ->
      build_button(dbutton)
    end))
    lines = lines ++ ["</div>"]
    lines = lines ++ ["</form>"]

    lines
    |> List.flatten()
    |> Enum.join("\n")
  end

  def build_field(:hidden, dfield) do
    build_field(:input, %{dfield | type: :hidden})
  end
  def build_field(:input, %{type: :hidden} = dfield) do
    ~s(<input type="hidden" id="#{dfield.id}" name="#{dfield.name}" value="#{dfield.value}" />)
  end
  def build_field(:input, %{type: :email} = dfield) do
    ~s(<input type="email" id="#{dfield.id}" name="#{dfield.name}" value="#{dfield.value}" #{required(dfield)}/>)
  end
  def build_field(:input, %{type: :password} = dfield) do
    ~s(<input type="password" id="#{dfield.id}" name="#{dfield.name}" value="#{dfield.value}" #{required(dfield)}/>)
  end
  def build_field(:input, %{type: :naive_datetime} = dfield) do
    ~s(<input type="naive_datetime" id="#{dfield.id}" name="#{dfield.name}" value="#{dfield.value}" #{required(dfield)}/>)
  end
  def build_field(:input, %{type: :text} = dfield) do
    ~s(<input type="text" id="#{dfield.id}" name="#{dfield.name}" value="#{dfield.value}" #{required(dfield)}/>)
  end
  def build_field(:textarea, dfield) do
    """
    <textarea name="#{dfield.name}" id="#{dfield.id}" #{required(dfield)}>#{dfield.value}</textarea>
    """
  end
  def build_field(:select, dfield) do
    options = 
      dfield.options
      |> Enum.map(fn option ->
        cond do
        is_tuple(option) -> option
        is_binary(option) -> {option, option}
        true -> option # beurk
        end
      end)
      |> Enum.map(fn {title, value} ->
        selected = if value == dfield.value, do: ~s( selected="SELECTED"), else: ""
        ~s(<option value="#{value}"#{selected}>#{title}</option>)
      end)
      |> Enum.join("\n")

    """
    <select id="#{dfield.id}" name="#{dfield.name}">
    #{options}
    </select>
    """
  end


  def build_field(:captcha, dfield) do
    captcha = random_captcha()
    dfield = defaultize_field(%{
      tag:          :select,
      id:       "#{dfield.prefix}_captcha",
      name:     "#{dfield.prefix}[captcha]",
      defaultized: true, # pour ne pas modifier :id et :name
      label:    captcha.question,
      options:  Enum.shuffle(captcha.options),
      prefix:   dfield.prefix
    })
    select_field = build_field(:select, dfield)
    """
    <div class="explication">Merci de répondre à cette question pour nous assurer que vous êtes bien un être humain.</div>
    <label for="#{dfield.id}">#{dfield.label}</label>
    <input type="hidden" id="#{dfield.prefix}_captcha_index" name="#{dfield.prefix}[captcha_index]" value="#{captcha.index}" />
    #{select_field}
    """
  end


  # --- Méthodes Captcha ---

  @table_captcha [
    %{question: "Dans quelle catégorie peut-on ranger le mot “chaise” ?", options: ["meuble", "animal", "idée", "voyage"], answer: "meuble"},
    %{question: "Un livre est constitué de…", options: ["pages", "eau", "rubans", "voitures"], answer: "pages"},
    %{question: "Comment s'appelle le label ?", options: ["Renaudeau", "Valeurs sûres", "Lecture de Qualité"], answer: "Lecture de Qualité"},
    %{question: "Autour de quoi tourne la Terre", options: ["Le soleil", "Le pot de fleur", "Un point"], answer: "Le soleil"},
    %{question: "Quelle est la capitale de la France", options: ["Paris", "Marseille", "Londres", "Genève"], answer: "Paris"},
    %{question: "Comment est qualifié une femmme de grande taille", options: ["Géante", "Naine", "Reine", "Rassis"], answer: "Géante"},
    %{question: "En français, par quel signe se termine une question ?", options: ["?", "!", "¡", "¿"], answer: "?"},
    %{question: "Dans quel sport se sert-on d'une raquette ?", options: ["Tennis", "Football", "Tir à l'arc", "Cyclisme"], answer: "Tennis"},
    %{question: "Le handball est un sport…", options: ["d'équipe", "individuel", "reposant", "à raquette"], answer: "d'équipe"}
  ] |> Enum.with_index() |> Enum.map(fn {captcha, index} -> Map.put(captcha, :index, index) end)
  defp random_captcha do
    Enum.random(@table_captcha)
  end

  @doc """
  Pour vérifier la valeur du captcha
    Html.Form.captcha_valid?(data_formulaire)
    ou
    Html.Form.captcha_valid?(index, answer)
  """
  def captcha_valid?(index, answer) when is_integer(index) do
    Enum.at(@table_captcha, index).answer == answer
  end
  def captcha_valid?(index, answer) when is_binary(index) do
    captcha_valid?(String.to_integer(index), answer)
  end
  def captcha_valid?(form_data) do
    index   = form_data["captcha_index"]
    answer  = form_data["captcha"]
    captcha_valid?(index, answer)
  end

  @doc """
  Retourne la donnée captcha d'index +index+ (pour les tests)
  """
  def get_captcha_at(index) do
    Enum.at(@table_captcha, index)
  end


  def build_button(%{type: :submit} = dbutton) do
    ~s(<button type="submit" class="btn">#{dbutton.name}</button>)
  end


  # --- Méthodes privées ---

  defp explication(%{explication: nil} = _dfield) do
    ""
  end
  defp explication(dfield) do
    ~s(<div class="explication">#{dfield.explication}</div>)
  end

  defp required(dfield) do
    if dfield.required do
      " required" 
    else
      ""
    end
  end

  def label(dfield) do
    if dfield.label do
      ~s(<label for="#{dfield.id}">#{dfield.label}</label>)
    else "" end
  end

  def wrap(code, dfield) do
    if dfield.label do
      tag = dfield.wrapper
      "<#{tag}>#{code}</#{tag}>"
    else 
      code 
    end
  end

  # Pour que le formulaire passe
  def token_field do
    token = Plug.CSRFProtection.get_csrf_token()
    ~s(<input type="hidden" name="_csrf_token" value="#{token}">)
  end

  def calc_field_id(dfield) do
    cond do
      dfield[:id]         -> 
        "#{dfield.prefix}_#{dfield.id}"
      dfield[:strict_id]  -> 
        "#{dfield.prefix}_#{dfield.strict_id}"
      dfield[:name] || dfield[:strict_name] ->
        simple_name = dfield[:name] || dfield[:strict_name]
        if String.match?(simple_name, ~r/\[/) do
          simple_name
          |> String.replace("][", "_")
          |> String.replace(~r/[\[\]]/, "")
        else
          simple_name
        end
        "#{dfield.prefix}_#{simple_name}"
      true -> 
        "field_#{Ecto.UUID.generate()}"
    end
  end

  def calc_field_name(dfield) do
    prefix = dfield[:prefix]
    cond do
      Map.get(dfield, :strict_name) -> 
        dfield.strict_name
      is_nil(dfield[:name]) ->
        "#{prefix}[#{dfield[:id]||dfield[:default_id]}]"
      String.match?(dfield.name, ~r/\[/) -> 
        dfield.name
      true -> 
        "#{prefix}[#{dfield.name}]"
    end
  end

  defp defaultize_field(dfield) do
    dfield = 
      if is_nil(Map.get(dfield, :defaultized, nil)) do
        Map.put(dfield, :id, calc_field_id(dfield))
        |> Map.put(:name, calc_field_name(dfield))
        |> Map.put(:defaultized, true)
      else dfield end

    [
      {:explication, nil}, {:label, nil}, {:wrapper, "div"},
      {:type, nil}, {:required, false}, {:options, dfield[:values] || nil},
      {:value, nil}
    ] |> Enum.reduce(dfield, fn {prop, defvalue}, coll ->
      if Map.has_key?(coll, prop) do
        coll
      else
        Map.put(coll, prop, defvalue)
      end
    end)
  end
end