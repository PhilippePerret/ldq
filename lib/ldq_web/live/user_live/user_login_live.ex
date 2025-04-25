defmodule LdQWeb.UserLoginLive do
  use LdQWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Identification</h2>
    <div class="mx-auto max-w-sm">

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Mail" required />
        <.input field={@form[:password]} type="password" label="Mot de passe" required />
        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Me garder connecté" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Connexion..." class="w-full">
            Se connecter
          </.button>
        </:actions>
      </.simple_form>
    </div>
    <div>
      Pas encore de compte ? Vous pouvez 
      <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
        le créer maintenant
      </.link>
    </div>
    """
  end

  def mount(_params, session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    # J'ai rajouté backroute pour la redirection
    form = to_form(%{"email" => email, "backroute" => session["backroute"]}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
