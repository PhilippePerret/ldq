defmodule LdQ.Procedure.ProcedureObject do
  @moduledoc ~S"""
  Table d'association entre une procédure `LdQ.Procedure` et un sujet quelconque, en général un `LdQ.Comptes.User` (un auteur, un membre du comité de lecture) ou un `LdQ.Library.Book` (un livre)

  On peut obtenir une procédure concernant n'importe quel élément grâce aux trois éléments :

  ~~~text
  Procédure Dim             Type objet                ID objet      
  -------------             ----------                --------
  Le diminutif de la        Le type de l'objet        L'identifiant binaire
  procédure, par exemple    visé par la procédure     de l'objet.
  'book-evaluation'         par exemple 'book'
  ~~~

  Les types d'objet sont pour le moment :

  ~~~text
  'book'    Un livre soumis pour évaluation. `LdQ.Library.Book`
  'member'  Un membre du comité de lecture (ou cherchant à l'être) `LdQ.Comptes.User`
            Attention, ça pourrait devenir un `LdQ.Comptes.Membre`
  'author'  Un auteur ou une autrice de livre. `LdQ.Library.Author`
  'page'    Une page localisée (pour suivre sa fabrication par exemple ou
            son actualisation). `LdQ.Site.PageLocale`
  'gpage'   Une page générale (abstraite) donc au-dessus des pages localisées 
            qui sont dans toutes les langues. `LdQ.Site.Page`
  'proc'    Une procédure elle-même (pour savoir par exemple où en est son 
            implémentation). `LdQ.Procedure`
  ~~~
  
  > La propriété :proc_dim a été ajoutée simplement pour y voir plus clair dans la base, car on pourrait s'en passer puisqu'elle est définie dans la table de la procédure (on pourrait donc l'obtenir par simple jointure de table).


  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "procedures_objects" do
    field :object_id, :binary
    field :object_type, :string
    field :proc_dim, :string
    
    belongs_to :procedure, LdQ.Procedure

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(procedure_object, attrs) do
    procedure_object
    |> cast(attrs, [:procedure_id, :object_id, :object_type, :proc_dim])
    |> validate_required([:procedure_id, :object_id, :object_type, :proc_dim])
  end
end
