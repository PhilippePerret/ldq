defmodule LdQWeb.UserRegistrationLive do
  use LdQWeb, :live_view

  alias LdQ.Comptes
  alias LdQ.Comptes.User

  def render(assigns) do
    ~H"""
    <h2>Inscription</h2>
    <div class="mx-auto">
      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:name]} type="text" label="Votre nom" required />
        <.input field={@form[:email]} type="email" label="Votre adresse mail" required />
        <.input field={@form[:sexe]} type="select" label="On doit vous parler au…" options={[{"féminin", "F"},{"masculin", "H"}]} required />
        <.input field={@form[:password]} type="password" label="Votre mot de passe" required />

        <:actions>
          <.button phx-disable-with="Création de votre compte…">Créer votre compte</.button>
        </:actions>
      </.simple_form>
    </div>
    <div>
    Si vous êtes déjà inscrit(e), vous pouvez 
    <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
      vous identifier
    </.link>

    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Comptes.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Comptes.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Comptes.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        _changeset = Comptes.change_user_registration(user)
        # {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}
        {:noreply, push_navigate(socket, to: ~p"/inscrit/bienvenue")}
        
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Comptes.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
