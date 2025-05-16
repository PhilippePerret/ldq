
# defmodule LdQWeb.FormController do
#   use LdQWeb, :controller

#   # alias LdQ.Forms

#   alias LdQ.{Candidat,SubmittedBook,Procedure}

#   @doc """
#   Tous les formulaires personnalisés passent par ici
#   """
#   def edit(conn, %{"form" => form} = params) do
#     current_user = Map.get(conn.assigns, :current_user, nil)
#     params = Map.put(params, "user", current_user)

#     html_path = Path.join([__DIR__,"form_html", "#{form}.html.heex"])
#     if false == File.exists?(html_path) do
#       phil_path = Path.join([__DIR__, "_philhtml", "#{form}.phil"])
#       PhilHtml.to_html(phil_path, [dest_name: "#{form}.html.heex", dest_folder: "../form_html", no_header: true, helpers: [LdQ.Site.PageHelpers]])
#     end

#     changeset = get_data_by_form(form, params)

#     render(conn, "#{form}.html", %{
#       current_user: current_user,
#       changeset: changeset
#     })
#   end

#   def create(conn, %{"form" => form} = params) do
#     # IO.inspect(params, label: "\nParams dans create")
#     {redirection, message} = on_create(form, params)

#     conn = if is_nil(message) do conn else
#       put_flash(conn, :notice, message)
#     end
#     conn
#     |> redirect(to: redirection)
#   end

#   def on_create("candidature-comite", params) do
#     Procedure.CandidatureComite.start(params)
    
#     {~p"/pg/on-submit-candidature-comitee", nil}
#   end


#   def get_data_by_form("evaluation-livre", params) do
#     book = Map.get(params, "book", %{})
#     SubmittedBook.changeset(%SubmittedBook{}, %{
#       title:              book["title"],
#       subtitle:           book["subtitle"],
#       isbn:               book["isbn"],
#       resume:             book["resume"],
#       main_genre:         book["main_genre"],
#       sub_genre:          book["sub_genre"],
#       user_id:            book["user_id"]||(book["user"] && book["user"].id),
#       user_mail:          book["user_mail"]||(book["user"] && book["user"].email),
#       main_author_email:  book["main_author_email"],
#       transmit_book:      book["transmit_book"]||true,
#       url_command:        book["url_command"]
#     })
#   end

#   def get_data_by_form(unknown, _params) do
#     raise "Le formulaire #{inspect unknown} est inconnu"
#   end
# end
