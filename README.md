# OpenDataWine

Interface de consultation et d'accessibilité aux données des délimitations parcellaires des AOC françaises : https://www.opendatawine.fr

## Récupération du dépôt

Le dépôt est gros pour le récupéré on peut utiliser sparse-checkout :

```
git clone --no-checkout git@github.com:24eme/opendatawine.git
git sparse-checkout set --no-cone '/*' '!/delimitation_aoc'
git checkout master
```

Pour mettre à jour la branche `githubpage` depuis la branche `master` :

```
bash bin/publish_to_githubpages.sh
```
