defmodule LdQ.Comptes.Helpers do
  @moduledoc ~S"""
  Module d'helpers pour les comptes, à commencer par les users.

  > #### Attention {: .error}
  >
  > Il est inutile d'appeler directement ce module car il est importé dans LdQ.Comptes.
  > Donc utiliser `!LdQ.Comptes.email_link_for/2` plutôt que `LdQ.Comptes.Helpers.email_link_for/2`.

  """
  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Comptes.{User, Membre, MemberCard, UserToken, UserNotifier}
  alias LdQ.Evaluation.UserBook


  @doc """
  Helper retournant un \<a-lien\> pour envoyer un message à l'utilisateur fourni en premier argument.

  ## Exemples

      LdQ.Comptes.email_link_for(user, title: "Bonjour")
      # => <a href="mailto:usermail@chez.lui">Bonjour</a>

      LdQ.Comptes.email_link_for(user, title: "Bonjour", subject: "Mon sujet")
      # => <a href="mailto:usermail@chez.lui?subject=Mon+sujet">Bonjour</a>


  ## Tests

    iex> LdQ.Comptes.email_link_for(%User{email: "sonemail@chez.lui", name: "You"})
    ~s(<a href="mailto:sonemail@chez.lui">You</a>)

    iex> LdQ.Comptes.email_link_for(%User{email: "sonemail@chez.lui", name: "You"}, [title: "Le titre", subject: "Le sujet"])
    ~s(<a href="mailto:sonemail@chez.lui?subject=Le+sujet">Le titre</a>)
  
  """
  @spec email_link_for(user :: LdQ.Comptes.User, options :: keyword()) :: any()
  def email_link_for(user, options \\ []) do
    title = 
      case options[:title] do
        nil     -> user.name
        :name   -> user.name
        :email  -> user.email
        :mail   -> user.email
        title  -> title
      end
    comp_subject = if options[:subject] do
      ~s(?#{URI.encode_query(%{subject: options[:subject]})})
    else "" end

    ~s(<a href="mailto:#{user.email}#{comp_subject}">#{title}</a>)
  end

end