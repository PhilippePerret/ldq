defmodule LdQWeb.AproposController do
	use LdQWeb, :controller
	
		def afficher(conn, %{"page" => page_a_voir} = params) do
			page_pre = get_referer(conn, params)
			|> IO.inspect(label: "REFERER retourné : ")
			cond do
			in_pages_list?(page_a_voir) ->
				render(conn, String.to_atom(page_a_voir), layout: {LdQWeb.Layouts, :as_page}, page_pre: page_pre)
			true -> 
				conn 
				|> put_flash(:error, dgettext("msg","The page “%{page}” is unknown.", page: page_a_voir))
				|> redirect(to: ~p"/")
			end
		end

		def	afficher(conn, _params), do: afficher(conn, %{"page" => "manifeste"})

		def get_referer(conn, %{"anchor" => anchor} = _params) do
			referer = get_referer(conn, %{})
			referer && (referer <> "##{anchor}") || nil
		end

		def get_referer(conn, _params) do
			[referer] = get_req_header(conn, "referer") || [nil]
			[host] 		= get_req_header(conn, "host")
			IO.inspect([referer, host], label: "[REFERER, HOST]:")
			String.match?(referer, ~r/#{host}/) && referer || nil
		end


		defp in_pages_list?(page) do
			Enum.member?([
					"bons_livres_en_ae",
					"chiffres_publication",
					"choix_membres",
					"faq",
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