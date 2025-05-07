# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LdQ.Repo.insert!(%LdQ.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


alias LdQ.Repo
alias LdQ.Comptes.User
alias LdQ.Site.{Page,PageLocale}
import Ecto.Query

hashed_password = Bcrypt.hash_pwd_salt("xadcaX-huvdo9-xidkun")

email_phil = "philippe.perret@yahoo.fr"

# Seulement en mode :dev et si je ne suis pas encore enregistré
if (Mix.env() == :dev) and is_nil(Repo.one(from(u in User, where: u.email == ^email_phil))) do
  Repo.insert!(%User{
    name: "Phil", 
    email: email_phil,
    sexe: "H",
    hashed_password: hashed_password,
    privileges: 64
  })
end

# ==== Pages et Pages Locales ====



Repo.delete_all(PageLocale)
Repo.delete_all(Page)

path_folder = Path.join(["assets","pages","fr"])
File.ls!(path_folder)
|> Enum.filter(fn path -> String.ends_with?(path, ".phil") end)
|> Enum.each(fn path ->
  slug = Path.rootname(path)
  fullpath = Path.join([path_folder, path])
  page = Repo.insert!(%Page{
    slug: slug, 
    template: "plain_page", 
    status: 5
  })

  # On récupère les données dans l'entête du fichier .phil
  pdata = PhilHtml.to_data(fullpath, [evaluation: false, to_file: false, no_header: true])
  
  [title, summary] =
    if Map.has_key?(pdata.metadata, :title) do
      tit = pdata.metadata.title || "#{slug à nommer}"
      sum = pdata.metadata.summary || "-- RÉSUMÉ À DÉFINIR ---"
      [tit, sum]
    else
      IO.puts [IO.ANSI.red() <> "Il faut définir l'entête du fichier" <> IO.ANSI.reset()]
      ["#{slug} À RENOMMER", "-- RÉSUMÉ À DÉFINIR ---"]
    end

  html_path = Path.join([path_folder, "xhtml", "#{slug}.html"])
  content = if File.exists?(html_path) do
    File.read!(html_path)
  else "À TRANSVASER" end

  locpage = Repo.insert!(%PageLocale{
    page_id:      page.id,
    locale:       "fr",
    status:       5,
    title:        title,
    raw_content:  File.read!(Path.join([path_folder, path])),
    content:      content,
    summary:      summary
  })
  IO.puts "-> #{slug} OK"
end)


# Ajouter quelques éditeurs connus
Repo.insert!(%LdQ.Libray.Publisher{
  name: "Icare Éditions",
  pays: "fr",
  address: "2 rue Goritz 4000 Mont-de-Marsan",
  email: "contact@icare-editions.fr"
})