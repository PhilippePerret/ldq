defmodule LdQWeb.UserSessionController do
  use LdQWeb, :controller

  import LdQ.Helpers.Feminines

  alias LdQ.Comptes
  alias LdQWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, dgettext("msg", "Account created successfully!"))
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:backroute, ~p"/users/settings")
    |> create(params, dgettext("msg", "Password updated successfully!"))
  end

  def create(conn, params) do
    create(conn, params, dgettext("msg", "Welcome back!"))
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Comptes.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, dgettext("msg", "Invalid email or password"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    user = conn.assigns.current_user
    conn
    |> put_flash(:info, "Vous êtes bien déconnecté#{fem(:e, user)}.")
    |> UserAuth.log_out_user()
  end
end
