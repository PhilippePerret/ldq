# Tests du site Lecture de Qualité

## Tests d'intégration

Pour le moment, les tests d'intégration doivent se lancer un par un… Mais j'ai fait un script qui permet de simuler ce lancement un par un. Il suffit de jouer dans la console (à la racine de l'application) : 

~~~
> ruby test/feature/__test_runner__.rb
~~~

Des options permettent de préciser ce qu'on veut faire : 

| Option | abr. | Effet |
| --- | --- | --- |
|     |       |  On demande le dossier à jouer (ou il est précisé en dernier argument par son nom) |
| --all | -a | Jouer tous les tests  de tous les dossiers |
| --dir | -d | Jouer tous les tests du dossier choisi (ou précisé en dernier argument) |
| --one | -o | On peut choisir un seul script à jouer (le dossier peut être indiqué en dernier argument) |
| --from | -f | Le test à partir duquel commencer |
| --to | -t | Le dernier test à jouer |
| --same | -s | Les mêmes tests que ceux qui viennent d'être effectués |

Sinon, on peut bien sûr lancer le test que l'on veut de façon traditionnelle :

~~~
mix test test/feature/<dossier>/<fichier exact>
~~~

Par exemple : 

~~~
mix test test/feature/book_evaluation/3.1-when-author.exs
~~~

> Il faut comprendre que pour une raison inconnue pour le moment, on ne peut pas lancer tous les tests à la suite, il faut les faire test par test et de façon isolée.

## Problèmes connus pouvant survenir

Suite à l'actualisation de Chrome, il peut y avoir un problème entre la version de Chrome et le `chromedriver`, qui fait plante sans que le message soit vraiment clair. Tester la version de chromedriver avec `chromedriver --version` dans un Terminal (ou la console de VSCode) et la version de Chrome, dans l'application, en mettant en adresse : `chrome://version`. Les deux versions doivent coïncider.
