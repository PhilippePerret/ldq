defmodule LdQ.Comptes.Getters do
  @moduledoc ~S"""
  Module d'obtention des éléments de compte, à commencer par les users.

  > #### Attention {: .error}
  >
  > Il est inutile d'appeler directement ce module car il est importé dans LdQ.Comptes.
  > Donc utiliser `!LdQ.Comptes.get_user_by_email/1` plutôt que `LdQ.Comptes.Getters.get_user_by_email/1`.

  """
  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Comptes.{User, Membre, MemberCard, UserToken, UserNotifier}
  alias LdQ.Evaluation.UserBook


  @doc """
  Obtient un user par son mail

  ## Examples

      i e x > get_user_by_email("foo@example.com")
      %User{}

      i e x > get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end


  @doc """
  Pour obtenir un simple utilisateur (`LdQ.Comptes.User`) par son identifiant binaire.

  Raises une erreur `Ecto.NoResultsError` si l'utilisateur n'existe pas.

  ## Tests

      iex> bddshot("evaluation-book/2-autorisation-auteur")
      iex> user = LdQ.Comptes.Getters.get_users([limit: 10]) |> Enum.at(0)
      iex> LdQ.Comptes.Getters.get_user!(user.id).id
      user.id

      i e x > LdQ.Comptes.Getters.get_user!(456)
      "** (Ecto.Query.CastError) "

  ## Propriétés

  **Propriétés naturelles** en base de données

    - `:name` - Le nom de l'user (Prénom Nom, normalement)
    - `:email`- Son adresse email
    - `:sexe` - Son sexe, "F" ou "H"
    - `:privileges` - Le flag de privilège de l'user. On peut envoyer l'user aux fonctions telles que `LdQ.Comptes.User.admin?/1`, `LdQ.Comptes.User.is_membre_college?/2` etc. pour connaitre son statut.

  En plus des propriétés normales (en base de données), la structure reçoit les **propriétés volatiles** suivantes :

    - `:privileges`
    - `:credit` - Le crédit de l'user (pour le moment, seuls les membres du comité de lecture en ont, mais à l'avenir, ça pourrait changer)
    - `:refs` - Un helper qui permet de marquer "Nom (id binaire)"
    - `linked_refs`- La même chose, mais avec un lien qu'on peut cliquer pour rejoindre le profil de l'utilisateur, quel que soit son statut.

  > #### Attention {: .error}
  > 
  > Avec cette méthode, qui ajoute beaucoup des propriétés volatiles, il faut impérativement que toutes ces propriétés soit ajoutées/définies en tant que propriétés virtuelles dans `LdQ.Comptes.User`.

  """
  def get_user!(id) do
    data_user =
      from(u in User)
      |> join(:left, [u], c in MemberCard, on: c.user_id == u.id)
      |> where([u, _c], u.id == ^id)
      |> select([u, _c], map(u, [:id, :name, :email, :sexe, :privileges]))
      |> select_merge([_u, c], %{member_card_id: c.id, credit: c.credit})
      |> Repo.all()
      |> Enum.at(0)

    data_user || raise(LdQ.Error, [msg: "NotAUser"])

    # On lui ajoute les propriétés volatiles qui peuvent être
    # utiles n'importe quand.
    data_user = add_user_volatile_properties(data_user)
    
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


  @doc """
  Retourne les users voulus, en respectant les paramètres fournis en argument.

  ## Paramètres

    - `options` - map pouvant contenir
      - `:member` - On doit retourner seulement les membres du comité de lecture
      - `:admin` - On ne retourne que les administrateurs.
      - `:sort` - Clé de classement de la liste des utilisateurs. Peut valoir
        - `:credit` - Classement par crédit descendant
        - `:credit_asc` - Idem mais ascendant
        - `:book_count` - Nombre décroissant de livres évalués
        - `:book_count_asc`- Idem mais ascendant
      - `:book_count` - On doit ajouter le nombre de livres lus.
      - `:limit` - Pour se limiter à un certain nombre de résultats.

  ## Retour
  
    {List} Liste des utilisateurs désirés, dans l'ordre voulu
  """
  def get_users(options) do

    classement_par_livre = options[:sort] == :book_count || options[:sort] == :book_count_asc
    require_books = classement_par_livre || options[:book_count]

    # Pour obtenir le nombre de livres (si requis)
    user_id_to_book_count =
      if require_books do
        from(
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
    query = if options[:limit] do
      limit(query, ^options[:limit])
    else query end

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

    allusers |> IO.inspect(label: "Users relevés")
  end




  # Fonction qui ajoute à l'user (qu'il soit membre, administrateur
  # ou n'importe quoi) des propriétés utiles (à commencer par celle
  # qui permet d'obtenir ses 'refs', l'écriture de son patronyme avec
  # son identifiant entre parenthèse, ou 'linked_refs', la même chose
  # mais comme un lien pour rejoindre ton profil)
  defp add_user_volatile_properties(data) do
    refs = "#{data.name} (#{data.id})"
    Map.put(data, :refs, refs)
    |> Map.put(:linked_refs, ~s(<a href="membre/#{data.id}">#{refs}</a>))
  end

end