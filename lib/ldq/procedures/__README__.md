# LdQ Procédures

[Suivre les étapes de création d'une nouvelle procédure](#create-proc)

Ce document décrit comment gérer les procédures

Convention :

1. Une procédure possède un identifiant unique (`proc_dim`) qui correspond exactement au nom du dossier qui la définit.
2. Ce dossier se trouve dans le dossier `priv/procedures` et contient un fichier qui s'appelle très exactement `run.ex` qui joue la procédure en question.
3. Ce fichier `run.ex` absolument :
  * une constante `@steps` qui définit les étapes de la procédure
  * une fonction `step/0` qui retourne cette constante
  * un import `import LdQ.ProcedureMethods` (qui permet notamment d'appeler la fonction `__run__/1` qui lance la procédure ainsi que toutes les fonctions utiles aux procédures, les envois de mail, etc.)
  * une fonction `__create__/2` pour créer la procédure (une nouvelle procédure est appelée par l'url `/proc/new/<proc dim>`). C'est cette fonction qui crée l'instanciation et l'enregistrement de la nouvelle procédure et qui appelle la première étape.
4. Chaque étape (ie chaque step dans `@steps`) correspond à une fonction du fichier `run.ex`. L'instance de procédure transmise à `__run__/1`définit la dernière étape jouée, donc on peut connaitre la suivante (celle d'après)

Pour entrainer ce mécanisme, on appelle la méthode `LdQ.Procedure.run/1` qui reçoit en argument l'instance (structure) de procédure dont il est question. C'est cette fonction (fixe) qui appelle la bonne méthode `__run__` après avoir chargé le bon fichier `run.ex`.

Les paramètres de l'URL doivent être ajouté à la structure `Procedure`.

Pour voir concrètement le mécanisme en route :

* Les liens `/proc/new/candidature-comite` de titre "Candidater au comité de lecture" (ou autre titre similaire) conduisent à la fonction `create/3` du module `LdQWeb.ProcedureController` dans `lib/ldq_web/procedure/`
* Une fois une candidature posée pour le comité de lecture, une procédure de dim `candidature-comite` est enregistré.
* Les administrateurs reçoivent un mail contenant un lien d'href `/prov/<id de procédure>` pour rejoindre la page de la procédure.
* Quand il clique sur ce lien, le router dirige l'administrateur vers `AdminController.procedure/2` qui se trouve dans le `lib/ldq_web/controllers/admin_controller.ex`
* Cette fonction récupère la procédure en question et met dans sa table les paramètres.
* Elle regarde aussi s'il y a un paramètre `nstep` dans l'url, qui permet de définir l'étape (dans `@steps`) à jouer. Si c'est le cas, elle remplace le `next_step` naturel de la procédure. Cette propriété permet de rediriger très facilement les procédures.
* Puis la fonction appelle la vue `procedure.html.heex`.
* Cette vue appelle enfin `LdQ.Procedure.run(@procedure)` qui se trouve dans `lib/ldq/procedure.ex` (là où est définit le schéma d'une procédure)
* Cette fonction charge le module de la procédure et invoque sa fonction `LdQ.Procedure.__run__/1` qui va lancer le processus.
* L'étape `procedure.next_step` est alors automatiquement jouée, elle exécute les opérations voulues et retourne le code à écrire dans la page (formulaire à remplir, confirmation d'opération, etc.).

### Redirection vers une autre étape

Il suffit de définir dans l'url `?nstep=<nom de la step>` pour jouer une autre étape que l'étape naturelle de l'opération courante.

## Définition des étapes

Les étapes successives doivent se définir dans la propriété `@steps` qui est une liste de `Map`.

Chaque map contient :

~~~elixir
%{
  name: "Nom humain de la step", 
  fun: :fonction_a_appeler, 
  required_admin: true
}
~~~

La fonction à appeler est toujours une fonction qui reçoit la structure de la procédure.

> Cette structure contient en plus une propriété `:params` qui contient les paramètres de l'url (donc par exemple les valeurs d'un formulaire).

<a name="create-proc"></a>

## Procédure de création d'une procédure

* Trouver un nom humain unique — appelé *dim* — pour la procédure (pour qu'il soit unique, il suffit de voir les noms donnés dans le dossier `priv/procedure` — les dossiers portent les noms/dims de leur procédure). Pour l'exemple, on fera la procédure **procedure-exemple**
* Créer le dossier de cette procédure, portant son dim, dans le dossier principal `priv/procedures` (exemple : dossier `priv/procedures/procedure-exemple/`).
* À l'intérieur de ce dossier, créer :
  * un fichier `run.ex`,
  * un dossier `mails` (pour mettre les mails)
* Dans le fichier `run.ex`, on doit mettre au minimum :

  ~~~elixir
  defmodule LdQ.Procedure.ProcedureExemple do
    # pour le nom ProcedureExemple, caméliser simplement le dim de
    # la procédure
    moduledoc "Description de la procédure…"
    import LdQ.ProcedureMethods # Impératif
    use Phoenix.Component # [option] pour les composant HEX (if any)
    alias LdQ.Comptes # [option] Pour les méthodes user

    def proc_name, do: "Nom de la procédure"

    @steps [
      # Ici vont être définies les étapes de la procédure
      %{name: "Ma première étape", fun: ma_toute_premiere_step, require_admin: false}
    ] |> Enum.with_index() |> Enum.map(fn {s, index} -> Map.put(s, :index, index) end)
    def steps, do: @steps

    def __create__(proc_dim, params) do
      # Ici le traitement de la création de la procédure et 
      # notamment :
      create_procedure(attrs_proc)
    end

    def ma_toute_premiere_step(procedure) do
      "<p>Je suis dans la première étape</p>"
    end

    # Ici seront définies toutes les autres fonctions des steps
  end
  ~~~
* Définir les étapes successives de cette procédure. Mener une réflexion profonde pour ne pas avoir à trop les modifier ensuite.
* Pour chaque `:fun` définie pour chaque étape/step, définir la fonction de même nom et recevant un seul argument, la procédure. Cette fonction doit retourner le texte à écrire dans la page.