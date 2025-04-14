defmodule LdQWeb.ChantierController do
	use LdQWeb, :controller
	
	def voie_sans_issue(conn, _params) do
		render(conn, :voie_sans_issue, route: conn.request_path)
	end

  def en_travaux(conn, _params) do
    render(conn, :en_travaux, route: conn.request_path)
  end
	

  def test_mail(conn, _params) do
    LdQ.Mailer.send_test_email()
    render(conn, :en_travaux, route: conn.request_path)    
  end
end
