defmodule LdQ.Comptes.User do
  @moduledoc """
  Module d'un User quelconque.

  Note : un membre est un User aussi.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Bitwise

  alias LdQ.Comptes


  # ==== A P I ===== #
  
  @doc """
  @api
  Permet d'actualiser le crédit de l'utilisation (note : c'est dans
  la table MemberCard qu'est consigné ce crédit)
  """
  def update_credit(user, new_value) do
    user.member_card_id || raise("Impossible d'ajouter du crédit à un membre qui n'a pas de carte de membre…")
    Comptes.MemberCard.update(user.member_card_id, %{credit: new_value})
    %{user | credit: new_value}
  end
  @doc """
  Méthode spéciale pour les chainages
  """
  def add_credit(points, user) do
    update_credit(user, user.credit + points
    )
  end
  
  # ==== S C H É M A ===== #

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :email, :string
    field :sexe, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :privileges, :integer, default: 0

    field :member_card_id , :binary   , virtual: true
    field :member_card    , :binary   , virtual: true
    field :credit         , :integer  , virtual: true
    field :book_count     , :integer  , virtual: true
    field :refs           , :string   , virtual: true
    field :linked_refs    , :string   , virtual: true
    # Si des propriétés sont ajoutées, elles doivent être aussi 
    # ajoutées à la structure Membre

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :sexe, :email, :password, :privileges, :confirmed_at])
    |> validate_required([:sexe, :name])
    |> unique_constraint([:name, :email])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  @doc """
  MON changeset. Rester prudent car je ne sais pas pourquoi il 
  n'existe pas d'origine, alors qu'il est créé pour tous les 
  schémas. Pour le moment, je m'en sers seulement pour définir
  les privilèges.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :sexe, :email, :privileges])
    |> validate_email([])
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 10, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, LdQ.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%LdQ.Comptes.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end


  @doc """
  Retourne true si l'utilisateur a les privilèges interrogés.
  
  """
  @bit_reader 2
  @bit_writer 4
  @bit_membre 8
  @bit_admin  16
  @bit_admin1 16
  @bit_admin2 32
  @bit_admin3 64

  @table_bit_privileges %{
    reader: @bit_reader,
    writer: @bit_writer,
    membre: @bit_membre,
    member: @bit_membre,
    admin:  @bit_admin,
    admin1: @bit_admin1,
    admin2: @bit_admin2,
    admin3: @bit_admin3
  }
  def table_bit_privileges, do: @table_bit_privileges

  def reader?(user),  do: has_bit?(user, @bit_reader)
  def writer?(user),  do: has_bit?(user, @bit_writer)
  def membre?(user),  do: has_bit?(user, @bit_membre)
  def admin1?(user),  do: has_bit?(user, @bit_admin1)
  def admin2?(user),  do: has_bit?(user, @bit_admin2)
  def admin3?(user),  do: has_bit?(user, @bit_admin3)
  def admin?(user, level) do
    case level do
    1 -> has_bit?(user, @bit_admin1)
    2 -> has_bit?(user, @bit_admin2)
    3 -> has_bit?(user, @bit_admin3)
    end
  end
  def admin?(u) do
    Flag.has?(u.privileges, 16) or Flag.has?(u.privileges, 32) or Flag.has?(u.privileges, 64)
  end

  def is_membre_college?(u, icollege) do
    membre?(u) && u.college == icollege
  end

  def has_bit?(user, bit) do
    (user.privileges &&& bit) == bit
  end

  @doc """
  Pour actualiser les privilèges de l'user

  @param {LdQ.Comptes.User} user L'utilisateur concerné
  @param {List>Atom} liste Liste des atoms correspondant aux privilè-
                            ges dans la table @table_bit_privileges
  @param {Boolean} ajout  True si c'est pour un ajout, False si c'est
                          pour un retrait du/des privilège/s
  """
  def update_privileges(%__MODULE__{} = user, liste, ajout \\ true) do
    new_privileges = 
      liste 
      |> Enum.reduce(user.privileges, fn priv_id, privs ->
        if ajout do
          bor(privs, @table_bit_privileges[priv_id])
        else
          bxor(privs, @table_bit_privileges[priv_id])
        end
      end)
    case Comptes.update_user(user, %{privileges: new_privileges}) do
    {:ok, _} -> true
    {:error, err} ->
      raise "Erreur rencontrée en updatant les privilèges : #{inspect err}"
    end
  end
end
