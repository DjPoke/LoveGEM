# GEM — guide rapide

LoveGEM est un bureau avec des fenêtres, un éditeur de texte et un interpréteur [GEMBASIC](BASIC%20help.md).

## Naviguer et ouvrir

Cliquez sur **Swap**, **Work**, **Play**, **Relax** ou **Trashcan** pour ouvrir leur fenêtre ou la ramener devant. Double-cliquez sur un dossier pour afficher son contenu dans une autre fenêtre.

| Fichier | Double-clic |
| --- | --- |
| `.bas` | Exécute le programme GEMBASIC. |
| `.txt` | Ouvre le notepad. |
| `.jpg`, `.png` | Ouvre le viewer d’images, redimensionnable. |
| `.ogg`, `.wav` | Ouvre le player audio avec **Play** et **Stop**. |

Pour éditer un `.bas`, sélectionnez son icône puis choisissez **File → Edit**, ou utilisez **Edit** dans son menu contextuel.

## Sélection et fichiers

- **Shift + glisser avec le bouton gauche** sur une zone vide trace un rectangle. Les icônes sélectionnées restent en surbrillance après le relâchement.
- **Shift + glisser avec le bouton gauche** depuis une icône sélectionnée transfère le groupe si tous ses éléments sont drag n droppables.
- Un clic gauche simple sur une icône efface la sélection multiple. L’icône qui a le focus peut servir aux actions File.
- Glisser un fichier ou un dossier vers une autre fenêtre **copie** son contenu ; la source reste en place. Les collisions reçoivent un suffixe de copie.

Le menu **File** agit sur la fenêtre de fichiers active :

| Entrée | Action |
| --- | --- |
| **Edit** | Ouvre le premier `.bas` sélectionné dans le notepad. |
| **Rename** | Renomme l’unique fichier ou dossier sélectionné ; validez avec le bouton **Rename** ou Entrée. |
| **Search** | Recherche un nom complet, sans distinguer la casse ; sélectionne et rend visible l’icône trouvée. |
| **New folder** | Crée `New folder`, puis `New folder (1)`, etc. |
| **New file** | Crée `New file.txt`, puis `New file (1).txt`, etc. |
| **Close window** | Ferme la fenêtre active. |
| **Select all / Select none** | Sélectionne ou désélectionne tous ses fichiers et dossiers, même hors écran. |
| **Delete** | Envoie la sélection dans Trashcan. |
| **Quit** | Quitte LoveGEM. |

## Corbeille et notepad

Déposez une icône ou une sélection sur **Trashcan** pour la retirer de son dossier et la conserver dans la corbeille. Dans la fenêtre Trashcan, clic droit sur un élément puis **Restore** le restaure. Clic droit sur l’icône du bureau puis **Empty** supprime définitivement le contenu de la corbeille.

Dans le notepad, **File → Save** ou **Ctrl+S** sauvegarde le fichier ; un bip confirme la réussite. **File → Quit** ou **Ctrl+Q** ferme le notepad. La position du curseur apparaît en bas. Pensez à sauvegarder avant de fermer : la fermeture ne sauvegarde pas automatiquement.

## Tri et préférences

**View** choisit le tri par nom, date (plus récent d’abord), taille (croissante) ou type. Les dossiers précèdent les fichiers. **Do not sort** conserve l’ordre fourni par le répertoire dans chaque groupe. Le choix s’applique aux fenêtres ouvertes et futures et est mémorisé ; par défaut, **Do not sort** est coché.

**Options → Set preferences** propose les thèmes présents dans `minGUI/themes` et quatre polices : **1** CPCMode1, **2** Born2bSportyV2, **3** OldWizard, **4** MEGAMAN10. **Ok** applique et mémorise les choix. Par défaut : thème **GEM**, police **1**.

Au premier démarrage, Work, Play et Relax sont remplis depuis leurs dossiers `examples`. Les dossiers déjà existants sont conservés. Les fichiers créés, préférences et choix de tri sont stockés dans le répertoire de sauvegarde de LÖVE.
