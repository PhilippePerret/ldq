defmodule LdQWeb.Layouts.App do
  
  alias Phoenix.LiveView.JS

  # Méthode pour ouvrir le menu principal utilisateur
  def toggle_menu_avatar do
    JS.toggle(
      to: "#main-menu-user",
      in: {"transition ease-out duration-200", "transform opacity-0 translate-y-[-10%]","transform opacity-100 translate-y-0"},
      out: {"transition ease-in duration-75","transform opacity-100 translate-y-0", "transform opacity-0 translate-y-[-10%]"}
    )
  end
end


