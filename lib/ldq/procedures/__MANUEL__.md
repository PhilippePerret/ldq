# LdQ Procédures

## TODO DANS CE DOCUMENT 

* Ajouter `import LdQ.Site.PageHelpers # formlink, ldb_label etc.`
* Ajouter `import Helpers.Feminines` pour bénéficier des féminines dans les messages en mettant `#{fem("<suffix>", procedure.user)}`,
* Orienter vers Html.Form pour les formulaires au lieu des composant Hex. Pour le `LdQ.Library.Book` c'est une obligation puisqu'il a un système de gestion différent

## Introduction

[Suivre les étapes de création rapide d'une nouvelle procédure](#create-proc)

Ce document décrit comment gérer les procédures

Convention :

1. Une procédure possède un identifiant unique (`proc_dim`) qui correspond exactement au nom du dossier qui la définit.
2. Ce dossier se trouve dans le dossier `priv/procedures` et contient un fichier qui s'appelle très exactement `_<proc_dim>.ex` qui joue la procédure en question (ne pas oublier le `_` devant le nom).
3. Ce fichier `_<proc_dim>.ex` contient absolument tous les éléments qu'on trouve dans la procédure modèle.

Pour entrainer ce mécanisme, on appelle la méthode `LdQ.Procedure.run/1` qui reçoit en argument l'instance (structure) de procédure dont il est question. C'est cette fonction (fixe) qui appelle la bonne méthode `__run__` après avoir chargé le bon fichier `_<proc_dim>.ex`.

Les paramètres de l'URL doivent être ajouté à la structure `Procedure`.

Pour voir concrètement le mécanisme en route :

* Les liens `/proc/new/candidature-comite` de titre "Candidater au comité de lecture" (ou autre titre similaire) conduisent à la fonction `create/3` du module `LdQWeb.ProcedureController` dans `lib/ldq_web/procedure/`
* Une fois une candidature posée pour le comité de lecture, une procédure de dim `candidature-comite` est enregistré.
* Les administrateurs reçoivent un mail contenant un lien d'href `/prov/<id de procédure>` pour rejoindre la page de la procédure.
* Quand il clique sur ce lien, le router dirige l'administrateur vers `AdminController.procedure/2` qui se trouve dans le `lib/ldq_web/controllers/admin_controller.ex`
* Cette fonction récupère la procédure en question et met dans sa table les paramètres contenu dans l'URL.
* Elle regarde aussi s'il y a un paramètre `nstep` dans l'url, qui permet de définir l'étape (`nstep` doit être le nom de la fonction dans une étape de `@steps`) à jouer. Si c'est le cas, elle remplace le `next_step` naturel de la procédure. Cette propriété permet de rediriger très facilement les procédures ou de choisir entre plusieurs étapes alternative (acceptation/refus, par exemple).
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
  required_admin: true,       # True si un administrateur est requis
  required_owner: true        # True si le propriétaire est requis
}
~~~

La fonction à appeler est toujours une fonction qui reçoit la structure de la procédure.

> Cette structure contient en plus une propriété `:params` qui contient les paramètres de l'url (donc par exemple les valeurs d'un formulaire).

<a name="create-proc"></a>

## Procédure de création d'une procédure

* Trouver un nom humain unique — appelé *dim* — pour la procédure (pour qu'il soit unique, il suffit de voir les noms donnés dans le dossier `priv/procedure` — les dossiers portent les noms/dims de leur procédure). Pour l'exemple, on fera la procédure **new-proc**
* Dupliquer le dossier `priv/procedures/xmodele_procedure` et :
  * changer son nom de dossier en `priv/procedures/new-proc/`,
  * changer le nom du fichier principal `_xmodele_procedure.ex` en `_new-proc.ex`,
  * renseigner tout ce qui doit l'être dans ce fichier à savoir principalement :
    * `proc_name/0`, le nom humain de la procédure, qui servira de titre `h2` dans la page,
    * `@steps`, constante définissant la liste des étapes avec leurs propriétés (cf. [définition des étapes](#define-steps)),
    * `procedure_attributes/1`, les attributs de base propre à la procédure (ceux qui seront enregistrés dans la table `procedures`),
    * `defaultize_procedure/1`, la fonction qui permet de mettre dans la procédure véhiculée dans chaque fonction des propriétés générales indispensables

<a name="define-steps"></a>

### Définition des étapes

Chaque étape doit impérativement contenir/définir :

* `name {String}` : Nom humain de l'étape en question, il sera mis dans un `h3` sous le titre principal de la procédure. Pour que ce titre ne soit pas affiché, cf. `no_name` ci-dessous.
* `no_name {Boolean}` : (propriété optionnelle) Si cette propriété est mise à True, le titre `name` ci-dessus n'est pas affiché dans la page.
* `fun {Atom}` : Nom de la fonction/1 principale de l'étape, celle qui sera appellée quand la procédure sera jouée. Cette donnée sert aussi d'identifiant à l'étape (par exemple pour `next_step` qui définit l'étape suivante du statut actuel).
  
  Ces fonctions reçoivent toute un seul paramètre, qui est la procédure elle-même avec toutes les données qui peuvent être ajoutées.
* `admin_required {Boolean}`: Pour savoir si un administrateur est requis pour l'étape,
* `user_required {Boolean}` : Pour savoir si l'user propriétaire de la procédure est requis. *Noter que ce propriétaire n'est pas toujours la personne concernée directement par la procédure. Pour l'évaluation des livres, par exemple, ça n'est pas obligatoirement l'auteur qui soumet son livre*.
* `required {Fonction par Atom}` : la fonction optionnelle qui doit retourner True pour que le visiteur ne soit pas renvoyé dans une impasse.


## Les textes des étapes

Les textes de chaque étape peut être défini dans un fichier dans le dossier `textes` de la procédure. Par convention, on donne au nom du fichier le nom de la fonction de la procédure, mais ça n'est pas une obligation. Ce doit être un fichier au format PhilHtml, donc avec l'extension `.phil`.

Pour obtenir le texte formaté, il suffit d'ajouter en fin de fonction : 

~~~
load_phil_text(__DIR__, "<nom fichier>", %{var: valeur})
~~~

Si on met `user: user` dans les variables, on pourra automatiquement bénéficier des valeurs `user_name`, `user_id`, `user_mail`, `user_sexe` qu'on pourra utiliser dans le code par : 

~~~
Bonjour <:: user_name ::>, comment allez-vous ?
~~~

On bénéficie aussi de toutes les féminines :

~~~
Je suis sorti<:: f_e ::> comme format<:: f_rice ::>.
~~~


## Envoi de mail

Utiliser la méthode générique `send_mail/3` qui reçoit les paramètres du message à envoyer.

Signature :

~~~
send_mail(to: <destinataire>, from: <expéditeur>, with: <data>)

<destinataire>
et <expéditeur>
  un LdQ.Comptes.User
  ou :admins, :admin, :membre, :reader

<data> Les données du mail
~~~

Pour obtenir les données par défaut du mail, utiliser `default_mail_data/1`. Cette fonction retourne une `Map` contenant :

~~~
default_mail_data(procedure) ->
%{
  procedure:  procedure,
  folder:     Le dossier de la procédure,
  user:       Owner de la procédure ou user cible,
  mail_id:    nil, # ID du mail à renseigner,
  variables:  %{}, {Map} Table des variables à renseigner
}
~~~

Exemple d'un mail aux membres du comité envoyé par l'administration :

~~~elixir
def mafonction(procedure) do

  mail_data = default_mail_data(procedure)
  mail_data = %{mail_data | mail_id: "mail-user-mafonction"}
  mail_data = %{mail_data | variables: %{variable: "sa valeur dans le mail"}}
  send_mail(to: procedure.user, from: :admin, with: mail_data)
end
~~~

### Rédaction du message du mail

C'est un fichier `.phil` de la forme :

~~~philhtml
---
subject = Le sujet du mail
---
Ch<:: f_ere ::> ami<:: f_e ::> membre du comité,

Ici le corps du message.

<: signature_administration :>
~~~


## Enregistrement d'un log (historique)

Utiliser la méthode `log_activity(params)` (ou la méthode originale `LdQ.Log.add(params)`).

Où `params` contient :

~~~
%{
  text:         {String} "Le message exact à enregistrer",
  public:       {Boolean} True si le message doit apparaitre pour le public,
                          dans l'histoire des dernières activités par exemple
                          Défaut: True donc ne mettre que si faux
  creator:      {LdQ.Comptes.User} Requis. Le créateur du log (l'user courant),
  owner:        {Any} Le propriétaire de log (un user ou un livre, par exemple)
  OU  
    owner_type: {String}
    owner_id    {Binary}
  # Optionnellement
  inserted_at:  {NaiveDateTime} Pour mettre une autre date que maintenant
}
~~~
