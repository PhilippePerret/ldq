defmodule LdQWeb.AproposController do
	use LdQWeb, :controller

	@pages_valides [
		"bons_livres_en_ae",
		"chiffres_publication",
		"choix_membres",
		"faire_connaitre",
		"faq",
		"filtrage_des_livres",
		"le_comite",
		"manifeste",
		"membres_comite",
		"portail",
		"qualite_me_discutee",
		"realisabilite",
		"un_bon_livre"
	]

	def afficher(conn, %{"page" => page_a_voir} = params) do
		page_pre = get_referer(conn, params)
		case in_pages_list?(page_a_voir) do
			true ->
				check_phil_page(page_a_voir)
				render(conn, String.to_atom(page_a_voir), layout: {LdQWeb.Layouts, :plain_page}, page_pre: page_pre)
		false -> 
			conn 
			|> put_flash(:error, dgettext("msg","The page “%{page}” is unknown.", page: page_a_voir))
			|> redirect(to: ~p"/")
		end
	end

	def	afficher(conn, _params), do: afficher(conn, %{"page" => "manifeste"})

	def get_referer(conn, params) do
		if params["anchor"] do
			[referer] = get_req_header(conn, "referer") || [nil]
			[host] 		= get_req_header(conn, "host")
			if String.match?(referer, ~r/#{host}/) do
				referer <> "##{params["anchor"]}"
			else
				nil
				end
		else
			nil
		end
	end

	defp in_pages_list?(page) do
		Enum.member?(@pages_valides, page)
	end

  def check_phil_page(base) do
    root = Path.join([__DIR__,"apropos_html","#{base}"])
    phil = "#{root}.phil"
    PhilHtml.to_html(phil, [
      dest_name: "#{base}.html.heex", 
      no_header: true,
      evaluation: false
      ])
  end



end