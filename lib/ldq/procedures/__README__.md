# LdQ Procédures

Ce document décrit comment gérer les procédures

Convention :

1. Une procédure possède un identifiant unique (`proc_id`) qui correspond exactement au nom du dossier qui la définit.
2. Ce dossier contient un fichier qui s'appelle très exactement `run.ex` qui joue la procédure en question.
3. Ce fichier `run.ex` contient :
  * une méthode `__run__/1` qui permet de jouer la procédure (et reçoit en argument la structure de la procédure relative en question — structure %Procedure{} enregistrée dans la table à la création de l'instance de la procédure),
  * une constante `@steps` qui définit les étapes de la procédure
4. Chaque étape (ie chaque step dans `@steps`) correspond à une fonction du fichier `run.ex`. L'instance de procédure transmise à `__run__/1`définit la dernière étape jouée, donc on peut connaitre la suivante (celle d'après)

Pour entrainer ce mécanisme, on appelle la méthode `LdQ.Procedure.run/1` qui reçoit en argument l'instance (structure) de procédure dont il est question. C'est cette fonction (fixe) qui appelle la bonne méthode `__run__` après avoir chargé le bon fichier `run.ex`.

Question pour le moment : si deux procédures sont appelés à la suite, est-ce que la fonction `__run__/1` du second écrase la fonction du premier ?