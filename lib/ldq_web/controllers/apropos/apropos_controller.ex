defmodule LdQWeb.AproposController do
	use LdQWeb, :controller
	
		def afficher(conn, %{"page" => page_a_voir}) do
			page_a_voir =
				cond do
				in_pages_list?(page_a_voir) -> String.to_atom(page_a_voir)
				true -> :manifeste
				end
			render(conn, page_a_voir, layout: {LdQWeb.Layouts, :as_page})
		end

		def	afficher(conn, _params) do
			afficher(conn, %{"page" => "manifeste"})
		end

		defp in_pages_list?(page) do
			Enum.member?([
					"qualite_me_discutee", 
					"bons_livres_en_ae",
					"un_bon_livre",
					"le_comite"
				], 
				page
			)
		end
end