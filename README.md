# mailscan
Le script propose un scan periodique (hebdomadaire) des boites aux lettres (BAL) en vue d'éliminer les virus restant qui, pour certains raisons, 'ont pas étés détectes 'arrivée. 
Pour éviter le chargement inutile du serveur par un scan complet des anciens messages (parfois les BAL des utilisateurs ont des dizaines de GO) le script exécute un premier scan complet et après il vérifie seulement les messages de derniers 2 mois.
	 
Pour le bon fonctionnement du script le service de boîte aux lettres doit être configuré selon les normes recommandés (https://wiki.auf.org/wikiteki/Dovecot). Pour des configurations différentes il faudra adapter les paramètres du script.  

