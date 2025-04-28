defmodule LdQ.PhilHtml do

  import Phil.File, only: [file_mtime: 1]

  def check_feminize_file(base, main_folder, gvariables \\ %{}) do
    fname = Path.basename(main_folder)
    folder = Path.join([main_folder, "#{fname}_html"])
    root = Path.join([folder,"#{base}"])
    phil = "#{root}.phil"
    phil_mtime = file_mtime(phil)
    # Pour accélérer, on vérifie ici la nécessité d'updater/créer
    # les fichiers
    dest_f = "#{root}-F.html.hex"
    dest_h = "#{root}-H.html.hex"
    
    dest_f_exists = File.exists?(dest_f)
    dest_h_exists = File.exists?(dest_h)
    dest_f_mtime  = file_mtime(dest_f) 
    dest_f_is_ok  = dest_f_exists && NaiveDateTime.after?(dest_f_mtime, phil_mtime)
    
    updated_required = 
      if dest_f_is_ok && dest_h_exists do 
        dest_h_mtime  = file_mtime(dest_h) 
        dest_h_is_ok  = dest_h_exists && NaiveDateTime.after?(dest_h_mtime, phil_mtime)
        !dest_h_is_ok
      else
        # Inutile de tester puisque le féminin n'est déjà pas bon
        true
      end
    
    if updated_required do
      
      dest_f_exists && File.rm(dest_f)
      dest_h_exists && File.rm(dest_h)
      helpers = [LdQ.Site.PageHelpers, Helpers.Feminines]
      # Version féminine du fichier
      variables = gvariables |> Map.merge(Helpers.Feminines.as_map("F"))

      PhilHtml.to_html(phil, [
        dest_name: "#{base}-F.html.heex", 
        no_header: true,
        evaluation: true,
        variables: variables,
        helpers: helpers
        ])

      # Version masculine du fichier
      variables = gvariables |> Map.merge(Helpers.Feminines.as_map("H"))
      PhilHtml.to_html(phil, [
        dest_name: "#{base}-H.html.heex", 
        no_header: true,
        evaluation: true,
        variables: variables,
        helpers: helpers
        ])
    end

  end

end