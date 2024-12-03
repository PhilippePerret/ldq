defmodule LdQWeb.AproposController do
	use LdQWeb, :controller
	
		def afficher(conn, %{"page" => page_a_voir} = _params) do
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
					"bons_livres_en_ae",
					"chiffres_publication",
					"choix_membres",
					"filtrage_livre",
					"le_comite",
					"manifeste",
					"membres_comite",
					"portail",
					"qualite_me_discutee",
					"realisabilite",
					"un_bon_livre"
				], 
				page
			)
		end
end