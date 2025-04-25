defmodule LdQ.PhilHtml do

  def check_feminize_file(base, main_folder, gvariables \\ []) do
    fname = Path.basename(main_folder)
    folder = Path.join([main_folder, "#{fname}_html"])

    
    root = Path.join([folder,"#{base}"])
    phil = "#{root}.phil"
    
    # Version féminine du fichier
    variables = gvariables ++ LdQ.Helpers.Feminines.as_keyword("F")
    PhilHtml.to_html(phil, [
      dest_name: "#{base}-F.html.heex", 
      no_header: true,
      evaluation: true,
      variables: variables,
      helpers: [LdQ.Helpers.Feminines]
      ])

    # Version masculine du fichier
    variables = gvariables ++ LdQ.Helpers.Feminines.as_keyword("H")
    PhilHtml.to_html(phil, [
      dest_name: "#{base}-H.html.heex", 
      no_header: true,
      evaluation: true,
      variables: variables,
      helpers: [LdQ.Helpers.Feminines]
      ])

  end

end