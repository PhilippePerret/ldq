defmodule LdQWeb.AproposController do
	use LdQWeb, :controller
	
		def manifeste(conn, _params) do
			render(conn, :manifeste, layout: {LdQWeb.Layouts, :as_page})
			# render(conn, :manifeste)
		end
	
end