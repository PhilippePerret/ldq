defmodule LdQ.Comptes do
  @moduledoc """
  The Comptes context.
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Comptes.{User, Membre, MemberCard, UserToken, UserNotifier}
  alias LdQ.Library.Book
  alias LdQ.Evaluation.UserBook

  
  # === Helpers ===

  @doc """
  Retourne un lien pour envoyer un message à l'utilisateur par mail.

  @param {User} user L'utilisateur en question
  @param {Keyword} options Les options
    :title    Peut valoir :mail (l'adresse en titre) :name (le nom de l'user en titre) ou le titre explicitement
  @return {HTMLString} Un lien pour envoyer un email
  """
  def email_link_for(user, options \\ []) do
    title = 
      case options[:title] do
        nil     -> user.email
        :name   -> user.name
        :email  -> user.email
        :mail   -> user.email
        title   -> title
      end
    ~s(<a href="mailto:#{user.email}?subject=#{options[:subject]}">#{title}</a>)
  end

  @doc """
  Retourne les users voulus, en respectant les options +options.

  @parap {Keyword} options
    :sort   On classe d'après cette clé. On peut trouver :
            :credit           Classement descendant par crédit
            :credit_asc       Classement ascendant par crédit
            :book_count       Nombre de livres évalués (descendant)
            :book_count_asc   Nombre de livres évalués (ascendant)
    :book_count   On doit ajouter le nombre de livres lus

  @return {List of User} La liste des utilisateurs voulus, dans
  l'ordre voulu
  """
  def get_users(options) do

    classement_par_livre = options[:sort] == :book_count || options[:sort] == :book_count_asc
    require_books = classement_par_livre || options[:book_count]

    # Pour obtenir le nombre de livres (si requis)
    user_id_to_book_count =
      if require_books do
        query = from(
          ub in UserBook,
          group_by: ub.user_id,
          select: %{uid: ub.user_id, count: count(ub.book_id)}
        )
        |> Repo.all()
        |> Enum.reduce(%{}, fn res, tbl ->
          Map.put(tbl, res.uid, res.count)
        end)
        # |> IO.inspect(label: "TABLE USER ID -> BOOK COUNT")
      else nil end

    query = from(
      u in User, 
      join: c in MemberCard, on: u.id == c.user_id,
      select: %{u | credit: c.credit}
    )

    # - Les privilèges -
    query = 
      if options[:member] || options[:membre] do
        where(query, [u, _c], fragment("(? & ?) != 0", u.privileges, 8))
      else 
        query 
      end
    query = 
      if options[:admin] do
        where(query, [u, _c], fragment("(? & ?) != 0", u.privileges, ^(16 + 32 + 64)))
      else 
        query 
      end

    query =
      if options[:sort] do
        case options[:sort] do
        :credit     -> 
          order_by(query, [_u, c], desc: c.credit)
        :credit_asc -> 
          order_by(query, [_u, c], asc: c.credit)
        _else -> 
          # Note : :books et :books_asc sont traités plus tard
          query
        end
      else 
        query
      end

    # On relève tous les utilisateurs correspondants
    allusers = Repo.all(query)

    # Ajout du nombre de livres si nécessaire
    allusers = 
      if require_books do
        allusers
        |> Enum.map(fn u -> Map.put(u, :book_count, user_id_to_book_count[u.id]) end)
      else allusers end

    # Faut-il classer par nombre de livres ?
    allusers =
      if options[:sort] == :book_count || options[:sort] == :book_count_asc do
        if options[:sort] == :book_count do
          Enum.sort(allusers, &(&2.book_count < &1.book_count))
        else
          Enum.sort(allusers, &(&2.book_count > &1.book_count))
        end
      else allusers end

    allusers
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  ATTENTION : AVEC CETTE FORMULE (PAS TRÈS CLAIRE…) IL FAUT 
  IMPÉRATIVEMENT QUE TOUTES LES PROPRIÉTÉS AJOUTÉES AUX DONNÉES
  DE L'USER SOIENT DES PROPRIÉTÉS VIRTUELLES (comme :credit — qui
  appartient à une autre table — et :book_count)
  """
  def get_user!(id) do
    data_user =
    query = from(u in User)
    |> join(:left, [u], c in MemberCard, on: c.user_id == u.id)
    |> where([u, _c], u.id == ^id)
    |> select([u, _c], map(u, [:id, :name, :email, :sexe, :privileges]))
    |> select_merge([_u, c], %{member_card_id: c.id, credit: c.credit})
    |> Repo.all()
    |> Enum.at(0)

    data_user || raise(LdQ.Error, [msg: "NotAUser"])
    
    Map.merge(%User{}, data_user)
  end

  def get_user_as_membre!(id) when is_binary(id) do
    user = get_user!(id) || raise(LdQ.Error, [msg: "NotAMember"])
    get_user_as_membre!(user)
  end
  def get_user_as_membre!(user) when is_struct(user, User) do
    User.membre?(user) || raise(LdQ.Error, [msg: "NotAMember"])
    membre = struct(Membre, Map.from_struct(user))
    # On ajoute les propriétés propres au membre
    Membre.add_props(membre)
  end

  def update_user(user, attrs) do
    user 
    |> User.changeset(attrs)
    |> Repo.update!()
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
