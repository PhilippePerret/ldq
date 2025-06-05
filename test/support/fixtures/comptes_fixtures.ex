defmodule LdQ.ComptesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Comptes` context.


  N001

    Si des users (simples users, membres, admins, etc.) doivent se
    connecter plus tard, il ne faut pas oublier de consigner leur
    mot de passe grâce aux méthodes TestHerlpers save_password_of/2
    ou save_passwords_of/1 (pour en enregistrer plusieurs)

  """

  alias LdQ.Repo
  import Ecto.Query
  import Bitwise
  import LdQ.LibraryFixtures
  import Random.Methods

  alias LdQ.Comptes
  
  # alias LdQ.{Comptes, Library}
  alias LdQ.Evaluation.UserBook

  def unique_user_email, do: "user#{uniq_int()}@example.com"
  def valid_user_password, do: "motdepasse"

  def valid_user_attributes(a \\ %{})
  def valid_user_attributes(nil), do: valid_user_attributes(%{})
  def valid_user_attributes(attrs) do
    [
      :name, :email, :sexe, :password
    ] |> Enum.reduce(attrs, fn prop, attrs ->
      if is_nil(Map.get(attrs, prop, nil)) do
        val =
        case prop do
          :name     -> "Stranger-#{uniq_int()}"
          :email    -> unique_user_email()
          :sexe     -> "F"
          :password -> valid_user_password()
        end
        Map.put(attrs, prop, val)
      else
        attrs
      end
    end)
  end

  def user_fixture(attrs \\ %{}) do
    attrs = rationnalize_user_attributes(attrs)
    # IO.inspect(attrs, label: "ATTRS pour user_fixture")
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Comptes.register_user()

    user =
      if attrs[:with_member_card] do
        member_card = Comptes.MemberCard.create_for(user)
        %{user | member_card_id: member_card.id}
      else
        user 
      end

    # IO.inspect(user, label: "\nUSER après membre-card")

    user = 
      unless is_nil(attrs[:credit]) do
        Comptes.User.update_credit(user, attrs[:credit])
      else user end

    user
  end

  # Transforme la donnée :privileges en entier si elle est donnée
  # par une liste de privilèges
  defp rationnalize_user_attributes(attrs) do
    attrs = 
      if !is_nil(attrs[:privileges]) and is_list(attrs.privileges) do
        bit_liste   = Comptes.User.table_bit_privileges
        priv_int = 
          Enum.reduce(attrs.privileges, 0, fn priv, val ->
            val_for_priv = bit_liste[priv] || raise("Le privilège #{inspect priv} est inconnu…")
            bor(val, val_for_priv)
          end)
        %{attrs | privileges: priv_int}
      else
        attrs        
      end

    # Si du crédit doit être ajouté à l'user, il faut qu'il ait une
    # carte de membre (MemberCard)
    attrs =
      unless is_nil(attrs[:credit]) do
        Map.put(attrs, :with_member_card, true)
      else attrs end

    attrs
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Récupère un simple user avec les paramètres +params+

  @param {Keyword} params Paramètres de choix (non utilisés pour le moment)
  """
  def get_simple_user(_params \\ []) do
    from(u in Comptes.User)
    |> where([u], u.privileges == 0)
    |> Repo.all()
    |> Enum.at(0)
  end

  @doc """
  Fait et retourne une simple user
  @param {Keyword|Map} params Les paramètres voulus dans l'user
  """
  def make_simple_user(params \\ %{}) do
    params = Phil.Map.ensure_map(params)
    attrs = Map.merge(%{
      password: Map.get(params, :password, valid_user_password()),
      privileges: 0
    }, params)
    user_fixture(attrs)
    |> Map.put(:password, attrs.password)
  end

  def make_simple_users(nombre, params \\ %{}) do
    (1..nombre)
    |> Enum.map(fn _x -> make_simple_user(params) end)
  end

  @doc """
  Contrairement aux users et autres authors, il n'y a pour le moment 
  qu'un seul administrateur, avec le mail :
  "admin@lecture-de-qualite.fr"
  S'il est déjà créé, on le retourne, sinon on le crée.
  """
  def make_admin(params \\ %{}) do
    email_admin     = "admin@lecture-de-qualite.fr"
    password_admin  = "passworddadministrateurpassepartout"
    case get_admin(Map.merge(%{email: email_admin}, params)) do
    {:ok, admin} -> admin
    :unknown ->
      his_number = uniq_int()
      new_attrs = %{
        name:       Map.get(params, :name, "Ben#{his_number} #{random_lastname()}"),
        email:      email_admin,
        password:   Map.get(params, :password, password_admin),
        privileges: Map.get(params, :privileges, [:admin3])
      }
      user_fixture(Map.merge(params, new_attrs))
    end |> Map.put(:password, params[:password] || password_admin)
  end

  @doc """
  Retourne un administrateur correspondant aux paramètres +params+
  """
  def get_admin(params \\ %{email: "admin@lecture-de-qualite.fr"}) do
    case Comptes.get_user_by_email(params.email) do
    nil   -> :unknown
    admin -> {:ok, admin}
    end
  end
  
  @doc """
  Fabrication d'un membre

  ATTENTION : Lire la N001
  """
  def make_membre(params \\ %{}) do
    sexe = random_sexe()
    prenom = random_prenom(sexe)
    uniqint = uniq_int()
    new_attrs = %{
      name:       Map.get(params, :name, "#{prenom}-#{uniqint} #{random_lastname()}"),
      email:      "membre#{uniqint}-comite@lecture-de-qualite.fr",
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, sexe),
      privileges: [:member],
      with_member_card: true
    }
    user = 
      user_fixture(Map.merge(params, new_attrs))
      |> Map.put(:password, new_attrs.password)

    if params[:with_credit] do
      Comptes.MemberCard.update(user.member_card_id, %{credit: Enum.random(10..10000) })
    end
    if params[:credit] do
      Comptes.MemberCard.update(user.member_card_id, %{credit: params[:credit]})
    end

    # A-t-il déjà lu des livres ?
    if params[:with_books] do
      # Si c'est le cas, on a 2 possibilités : 
      # 1- créer un nouveau livre qu'il a lu
      # 2- prendre un livre existant et lui faire lire
      nombre_livres = Enum.random(2..200)
      (1..nombre_livres)
      |> Enum.each(fn _x ->
        book = random_book_or_create(not_read_by: user)
        UserBook.assoc_user_and_book(user, book, %{note: Enum.random(0..40)})
      end)
    end

    user
  end

  @doc """
  Pour faire +nombre+ membres avec les paramètres +params+
  """
  def make_membres(nombre, params \\ %{}) do
    (1..nombre)
    |> Enum.map(fn _x -> make_membre(params) end)
  end

  @doc """

  @param {Keyword} params Les paramètres pour sélectionner le membre
    :id   {Binary} Par son identifiant
    :not  {Binary} Pas ce membre-là
    :min_credit {Integer} Le membre doit au minimum avoir ce crédit
    :max_credit {Integer} Le membre doit au maximum avoir ce crédit
    :do_not_create  Si True, on ne crée pas un nouveau membre quand on n'en trouve pas (la fonction retourne alors Nil)
  """
  def get_membre(params \\ []) do
    user =
      if params[:id] do
        Comptes.get_user!(params[:id])
      else
        query = from(u in Comptes.User, 
          join: c in Comptes.MemberCard, on: c.user_id == u.id)
        
        query =
          if params[:not] do
            where(query, [u, c], u.id != ^params[:not])
          else query end

        query =
          if params[:min_credit] do
            where(query, [u, c], c.credit >= ^params[:min_credit])
          else query end
        query = 
          if params[:max_credit] do
            where(query, [u, c], c.credit <= ^params[:max_credit])
          else query end

        Repo.all(query)
        |> Enum.at(0)
      end
    if is_nil(user) do
      if params[:do_not_create] do nil else
        attrs = %{}
        attrs = if params[:min_credit] do
          Map.put(attrs, :credit, params[:min_credit] + 10)
        else attrs end
        attrs = if params[:max_credit] do
          Map.put(attrs, :credit, params[:max_credit] - 10)
        else attrs end
        # On fait le membre
        make_membre(attrs)
      end
    else 
      # Quand le membre a pu être récupéré dans des membres 
      # existant
      # (note : on lui ajoute son mot de passe)
      TestHelpers.add_password_to!(user)
    end
  end

  # Cette méthode semble un vieil héritage de l'époque où les auteurs
  # des livres étaient des User spéciaux. Maintenant, les auteurs des
  # livres sont des LdQ.Library.Author (cf. make_author/2)
  def make_writer(params \\ %{}) do
    new_attrs = %{
      name:       Map.get(params, :name, "Caro#{uniq_int()}  #{random_lastname()}"),
      password:   Map.get(params, :password, valid_user_password()),
      sexe:       Map.get(params, :sexe, "F"),
      privileges: [:writer]
    }
    user_fixture(Map.merge(params, new_attrs))
    |> Map.put(:password, new_attrs.password)
  end

  def make_author(params \\ %{}), do: author_fixture(params)

end
