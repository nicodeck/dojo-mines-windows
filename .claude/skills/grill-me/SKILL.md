---
name: grill-me
description: Pose à l'élève les questions qui comptent avant de coder une nouveauté de son jeu.
disable-model-invocation: true
argument-hint: <la nouveauté>
---

L'élève décrit après la commande ce qu'il veut ajouter ou changer dans son jeu. S'il ne dit
rien, demande-lui et attends. Lis le code concerné avant de poser tes questions. Tu ne codes
pas pendant ce skill.

Construis l'**arbre de décision** de la nouveauté : chaque décision ouvre celles qui en
dépendent. La **frontière**, ce sont les décisions dont les prérequis sont déjà tranchés.

Avance par **tours**, **deux au plus**, de **cinq questions au plus**. À chaque tour, pose les
questions de la frontière qui comptent le plus pour l'élève, numérotées, chacune avec ta
recommandation, puis attends ses réponses. Une question qui dépend d'une autre du même tour
attend le tour suivant. Après le deuxième tour, tranche toi-même ce qui reste.

- Pose d'abord des questions de game design : ce que le joueur voit, fait et ressent.
- Pour la première version du jeu, une des questions porte sur l'ambiance visuelle.
- Ne pose une question technique que si la réponse change quelque chose pour l'élève. Explique
  alors l'enjeu et le compromis en mots simples.
- Les faits sont ton travail : si le code répond à une question, lis-le au lieu de demander.

Formule chaque question pour que « oui » accepte ta recommandation :

```
❓ **Q1 — <titre>** : <l'enjeu, puis les options>

➡️ Je recommande : <ta réponse, et pourquoi en une phrase>
```

Pour finir, résume les décisions, une par ligne, en marquant « (moi) » celles que tu as
tranchées seul. Demande ensuite à l'élève s'il valide. Tu codes seulement après son accord.
