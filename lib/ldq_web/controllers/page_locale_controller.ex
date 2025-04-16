defmodule LdQWeb.PageLocaleController do
  use LdQWeb, :controller

  alias LdQ.Site
  alias LdQ.Site.{Page, PageLocale}

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
        raw_content: File.read!(path),
        content: PhilHtml.to_html(path, [no_header: true, evaluation: false, helpers: [LdQ.Site.PageHelpers]])
      }
    else
      %PageLocale{}
    end
    changeset = Site.change_page_locale(new_map)
    render(conn, :new, changeset: changeset, params: common_params())
  end

  def create(conn, %{"page_locale" => page_locale_params}) do
    # On ne doit pas pouvoir créer une page avec le même :page_id et le
    # même :locale qu'une page existante.
    case Site.has_locale_page?(page_locale_params) do
      {:yes, id_page_locale} ->
        conn = conn 
        |> put_flash(:error, "Cette page locale existe déjà")
        show(conn, %{"id" => id_page_locale})
      :no ->
        case Site.create_page_locale(page_locale_params) do
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

  @doc """
  Fonction appelée pour actualiser le contenu brut (philhtml) de la
  page dans la base de donnée (et le contenu formaté)
  """
  def update_content(conn,  %{"id" => id}) do
    IO.puts "-> update_content avec id = #{id}"
    page_locale = Site.get_page_locale!(id)
    slug = page_locale.page.slug
    lang = page_locale.locale
    path = Path.join(["assets","pages", lang, "#{slug}.phil"])
    dest_path = Path.join(["assets","pages", lang, "#{slug}.html"])
    if File.exists?(dest_path), do: File.rm(dest_path)
    PhilHtml.to_html(path, [no_header: true, evaluation: false, helpers: [LdQ.Site.PageHelpers]])
    content = File.read!(dest_path)
    params = %{
      "id" => id, 
      "page_locale" => %{
        "id"          => id,
        "raw_content" => File.read!(path),
        "content"     => content
      }
    }
    update(conn, params)
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

  def update(conn, %{"id" => id, "page_locale" => page_locale_params}) do
    IO.inspect(page_locale_params, label: "params pour actualisation")
    page_locale = Site.get_page_locale!(id)

    case Site.update_page_locale(page_locale, page_locale_params) do
      {:ok, page_locale} ->
        conn
        |> put_flash(:info, "Page locale updated successfully.")
        |> redirect(to: ~p"/page_locales/#{page_locale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page_locale: page_locale, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    {:ok, _page_locale} = Site.delete_page_locale(page_locale)

    conn
    |> put_flash(:info, "Page locale deleted successfully.")
    |> redirect(to: ~p"/page_locales")
  end
end
