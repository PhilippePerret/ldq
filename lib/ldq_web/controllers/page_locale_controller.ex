defmodule LdQWeb.PageLocaleController do
  use LdQWeb, :controller

  alias LdQ.Site
  # alias LdQ.Site.{Page, PageLocale}
  alias LdQ.Site.PageLocale

  @doc """
  Fonction publique permettant d'afficher la page pour tout le monde


  @param {Map} params Les paramètres
  @param {String} params["back"] Slug de la page de retour (pour page_pre) (if any)
  @param {String} params["anchor"] Ancre de retour (if any)
  """
  def display(conn, %{"slug" => slug} = params) do
    lang = Map.get(params, "lang", "fr") # TODO PRENDRE LA LANGUE
    content = Site.get_page_locale_content(slug, lang)
    page_pre = if params["back"] do
      ~s(/pg/#{params["back"]}##{params["anchor"]})
    else nil end
    render(conn, "display.html", content: content, page_pre: page_pre, layout: {LdQWeb.Layouts, :plain_page})
  end

  @doc """
  Fonction atteinte par le route "/"
  """
  def home(conn, params) do
    display(conn, Map.put(params, "slug", "manifeste"))
  end


  def index(conn, _params) do
    page_locales = Site.list_page_locales()
    render(conn, :index, page_locales: page_locales)
  end

  defp common_params do
    %{}
    |> Map.put(:pages, Site.list_pages() |> Enum.map(&{&1.slug, &1.id}))
  end

  @doc """
  Pour créer une nouvelle page localisée

  De préférence, elle est créé depuis la fiche de la page canonique,
  c'est-à-dire que +params+, ici, définit "page" qui contient les
  paramètres "page_id" et "lang" définissant ces deux données. Dans
  ce cas, une page .phil est créée dans le dossier assets/pages de
  la langue.
  """
  # Quand la page canonique est définie
  def new(conn, %{"page" => _page} = params) do
    {dpage, params} = Map.pop!(params, "page")
    page = Site.get_page!(Map.get(dpage, "page_id"))
    lang = Map.get(dpage, "lang")
    path = Path.join(["assets", "pages", lang, "#{page.slug}.phil"])
    if not File.exists?(path) do
      code = """
      ---
      Page = #{page.slug}
      Created-at = #{NaiveDateTime.utc_now()}
      ---
      {Composer ici le texte de la page.}
      """
      File.write!(path, code)
    end
    params = Map.put(params, "locale", lang)
    params = Map.put(params, "page_id", page.id)
    params = Map.put(params, "slug", page.slug)
    conn = conn |> put_flash(:info, "Le fichier pour cette page localisée a été créé dans 'assets/pages/#{lang}/'.")
    new(conn, params)
  end
  def new(conn, params) do
    new_map =
    if Map.get(params, "locale") && Map.get(params, "page_id") do
      path = Path.join(["assets", "pages", params["locale"], "#{params["slug"]}.phil"])
      %PageLocale{
        locale: params["locale"], 
        page_id: params["page_id"],
        raw_content: File.read!(path)
      }
    else
      %PageLocale{}
    end
    changeset = Site.change_page_locale(new_map)
    render(conn, :new, changeset: changeset, params: common_params())
  end

  def create(conn, %{"page_locale" => locpage_params}) do
    # On ne doit pas pouvoir créer une page avec le même :page_id et le
    # même :locale qu'une page existante.
    case Site.has_locale_page?(locpage_params) do
      {:yes, id_page_locale} ->
        conn = conn 
        |> put_flash(:error, "Cette page locale existe déjà")
        show(conn, %{"id" => id_page_locale})
      :no ->
        case Site.create_page_locale(locpage_params) do
          {:ok, page_locale} ->
            conn
            |> put_flash(:info, "Page locale created successfully.")
            |> redirect(to: ~p"/page_locales/#{page_locale}")

          {:error, %Ecto.Changeset{} = changeset} ->
            IO.inspect(changeset, label: "\nErreur à l'enregistrement de la page locale")
            render(conn, :new, changeset: changeset, params: common_params())
        end
    end
  end

  def show(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    # IO.inspect(page_locale, label: "Page local dans :show")
    render(conn, :show, page_locale: page_locale)
  end

  def edit(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    changeset = Site.change_page_locale(page_locale)
    render(conn, :edit, page_locale: page_locale, changeset: changeset, params: common_params())
  end

  def update(conn, %{"id" => id, "page_locale" => locpage_params}) do
    # IO.inspect(locpage_params, label: "params pour actualisation")
    page_locale = Site.get_page_locale!(id)

    # On doit ajouter le contenu brut et formaté
    locpage_params = add_content_to_attrs(id, locpage_params)

    case Site.update_page_locale(page_locale, locpage_params) do
      {:ok, page_locale} ->
        conn
        |> put_flash(:info, "Page locale updated successfully.")
        |> redirect(to: ~p"/page_locales/#{page_locale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page_locale: page_locale, changeset: changeset)
    end
  end

  @doc """
  Fonction qui reçoit les attributs de la page locale tels qu'ils
  ont été fournis par le formulaire et y ajoute le contenu brut et le
  contenu formaté en les relevant dans les fichiers assets/pages
  """
  def add_content_to_attrs(id, attrs) do
    page_locale = Site.get_page_locale!(id)
    slug = page_locale.page.slug
    lang = page_locale.locale
    phil_path = Path.join(["assets","pages", lang, "#{slug}.phil"])
    html_path = Path.join(["assets","pages", lang, "xhtml", "#{slug}.html"])
    PhilHtml.to_html(phil_path, [dest_folder: "./xhtml", no_header: true, evaluation: false, helpers: [LdQ.Site.PageHelpers]])
    raw_content = File.read!(phil_path)
    content = File.read!(html_path)
    Map.merge(attrs, %{"raw_content" => raw_content, "content" => content})
  end

  @doc """
  Fonction pour forcer l'actualisation du contenu formaté de la page

  Ça force l'actualisation même si le fichier .phil n'a pas été 
  modifié. C'est nécessaire lorsque l'on change des fonctions, voire
  l'extension philhtml par exemple.
  """
  def update_content(conn, %{"id" => id} = params) do
    page_locale = Site.get_page_locale!(id)
    slug = page_locale.page.slug
    lang = page_locale.locale
    html_path = Path.join(["assets","pages", lang, "xhtml", "#{slug}.html"])
    File.exists?(html_path) && File.rm(html_path)

    update(conn, Map.put(params, "page_locale", %{}))
  end

  def delete(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    {:ok, _page_locale} = Site.delete_page_locale(page_locale)

    conn
    |> put_flash(:info, "Page locale deleted successfully.")
    |> redirect(to: ~p"/page_locales")
  end
end
