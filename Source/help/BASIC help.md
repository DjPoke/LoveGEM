# GEMBASIC — référence

LoveGEM est un environnement GEM créé avec Löve. Cette aide décrit les commandes actuellement analysées et exécutées par son interpréteur BASIC.

## Lancer un programme

Double-cliquez sur un fichier `.bas` dans une fenêtre Swap, Work, Play ou Relax. Le programme est chargé, analysé, puis exécuté progressivement dans `GEMBASIC_update()`. Une erreur indique la ligne concernée.

Après `END` ou la dernière instruction, l'écran reste affiché. Appuyez sur une touche ou cliquez pour revenir au bureau.

## Syntaxe générale

- Les commandes, fonctions et variables ne distinguent pas majuscules et minuscules.
- Une instruction par ligne ; `:` permet aussi de séparer des instructions simples sur une ligne.
- Les blocs de conditions et de boucles utilisent les retours à la ligne présentés ci-dessous.
- Les arguments sont séparés par des virgules.
- Les chaînes sont entourées de guillemets doubles : `"Bonjour"`.
- Une variable doit recevoir une valeur avant d'être lue. Ses noms peuvent contenir des lettres, chiffres et `_`, mais ne commencent pas par un chiffre.
- `REM` introduit un commentaire jusqu'à la fin de la ligne. L'apostrophe est aussi reconnue par le lexer comme début de commentaire.

```basic
REM Exemple d'affectation
score = 10
score = score + 5
PRINT score
END
```

Les chaînes acceptent notamment `\n`, `\t`, `\r`, `\"`, `\\`, les codes décimaux comme `\65` et hexadécimaux comme `\x41`. Les codes numériques représentent des octets de 0 à 255.

## Affichage et entrée

| Commande | Syntaxe | Effet |
| --- | --- | --- |
| `CLS` | `CLS` | Efface l'écran et remet le curseur en colonne 1, ligne 1. |
| `MODE` | `MODE 0` ou `MODE 1` | Sélectionne la police du mode 0 ou 1. |
| `PEN` | `PEN rouge, vert, bleu` | Définit la couleur du texte et des tracés ; utilisez des composantes de 0 à 255. |
| `LOCATE` | `LOCATE colonne, ligne` | Positionne le curseur en cellules de texte, avec des entiers positifs à partir de 1. |
| `PRINT` | `PRINT expression` | Affiche la valeur au curseur, puis avance à la ligne suivante, colonne 1. |
| `PRINT` | `PRINT texte, x, y` | Avec exactement trois arguments dont les deux derniers sont numériques, affiche en coordonnées pixels sans déplacer le curseur. |
| `WAITKEY` | `WAITKEY` | Attend un nouvel appui sur une touche. |
| `WAITMOUSE` | `WAITMOUSE` | Attend que les boutons soient relâchés, puis un nouvel appui sur un bouton de souris. |
| `END` | `END` | Termine l'exécution et conserve l'écran jusqu'à une touche ou un clic. |

`PRINT` accepte plusieurs expressions : une virgule ajoute une tabulation ; un point-virgule concatène les valeurs sans espace. Attention à la forme spéciale `PRINT texte, x, y` décrite dans le tableau. Dans la version actuelle, un point-virgule final n'empêche pas le passage à la ligne.

```basic
CLS
MODE 1
PEN 255, 255, 0
LOCATE 5, 3
PRINT "Bonjour LoveGEM"
PRINT "Score : "; 42
WAITKEY
END
```

`LOCATE` tient compte des dimensions de la police sélectionnée. Ses coordonnées sont distinctes des coordonnées pixels de la forme à trois arguments de `PRINT`.

## Chemins du programme

Deux variables sont initialisées à chaque lancement :

| Variable | Valeur |
| --- | --- |
| `EXEPATH` | Dossier du programme, avec `/` final ; chaîne vide si le programme est à la racine. |
| `EXEFILE` | Chemin complet du fichier `.bas` dans le système de fichiers LÖVE. |

Les chemins des ressources sont relatifs au système de fichiers LÖVE, pas automatiquement au dossier du programme. Utilisez `EXEPATH` pour charger une ressource voisine :

```basic
LOADMUSIC EXEPATH + "Music.ogg", 1
PLAYMUSIC 1
WAITKEY
STOPMUSIC 1
END
```

Par exemple, pour `Play/Games/Pong/Pong.bas`, `EXEPATH` vaut `Play/Games/Pong/`.

## Dessin

Le canvas BASIC mesure **480 × 270 pixels**. L’origine `(0, 0)` est en haut à gauche ; X augmente vers la droite, Y vers le bas. Les coordonnées visibles vont de `(0, 0)` à `(479, 269)`. Le curseur graphique est remis à `(0, 0)` au lancement ; il est indépendant du curseur texte de `LOCATE`.

| Commande | Effet |
| --- | --- |
| `MOVE x, y` | Positionne le curseur graphique sans dessiner. |
| `MOVER dx, dy` | Déplace le curseur graphique relativement, sans dessiner. |
| `PLOT x, y` | Dessine un point et positionne le curseur graphique. |
| `PLOTR dx, dy` | Déplace le curseur relativement et dessine un point. |
| `DRAW x, y` | Trace du curseur à `(x, y)`, puis y place le curseur. |
| `DRAWR dx, dy` | Trace vers une position relative, puis y place le curseur. |

Les lignes incluent leurs deux extrémités. Utilisez `PEN r, g, b` pour leur couleur. `CLS` remet le curseur texte à `(1, 1)`, sans déplacer le curseur graphique.

```basic
CLS
PEN 255, 255, 255
MOVE 20, 20
DRAWR 100, 0
DRAWR 0, 60
DRAWR -100, 0
DRAWR 0, -60
PLOT 70, 50
END
```

## Images et sprites

| Commande | Effet |
| --- | --- |
| `LOADIMAGE chemin, numero` | Charge une image dans un emplacement numéroté. |
| `DRAWIMAGE numero, x, y` | Dessine l’image chargée à sa taille native. |
| `LOADSPRITE chemin, numero, largeur, hauteur` | Découpe une spritesheet en frames de cette taille. |
| `DRAWSPRITE numero, frame, x, y` | Dessine une frame du sprite chargé. |

`LOADSPRITE` exige des dimensions entières positives qui divisent exactement celles de l’image, et un numéro de sprite entier positif ou nul. Les frames commencent à **1**, de gauche à droite, puis de haut en bas. Charger une image ou un sprite ne l’affiche pas : utilisez la commande de dessin correspondante.

`DRAWSPRITE` accepte de quatre à neuf arguments, dans cet ordre :

```basic
DRAWSPRITE numero, frame, x, y, rotation, echelleX, echelleY, origineX, origineY
```

Les arguments après Y sont facultatifs. Rotation en radians : défaut `0`. Échelle X : défaut `1`. Échelle Y : défaut de l’échelle X. Origine X et Y : défaut `0`. L’origine est exprimée dans la frame. Les images et sprites utilisent la couleur `PEN` courante comme teinte ; choisissez le blanc pour conserver leurs couleurs.

```basic
PEN 255, 255, 255
LOADIMAGE EXEPATH + "Background.png", 1
DRAWIMAGE 1, 0, 0
LOADSPRITE EXEPATH + "Sprites.png", 1, 32, 32
DRAWSPRITE 1, 1, 100, 80
DRAWSPRITE 1, 2, 160, 80, 0, 2, 2
END
```

Cet exemple suppose que les images existent et que `Sprites.png` contient au moins deux frames de 32 × 32 pixels. Une frame absente ou un fichier impossible à charger produit une erreur BASIC.

## Musiques et sons

| Commande | Effet |
| --- | --- |
| `LOADMUSIC chemin, numero` | Charge une musique en streaming. |
| `PLAYMUSIC numero` | Lance la musique chargée. |
| `STOPMUSIC numero` | Arrête la musique. |
| `LOOPMUSIC numero, valeur` | Active la boucle avec `1`/`TRUE`, la désactive avec `0`/`FALSE`. |
| `LOADSOUND chemin, numero` | Charge un son en mémoire. |
| `PLAYSOUND numero` | Lance le son chargé. |
| `STOPSOUND numero` | Arrête le son. |

Les emplacements des images, sprites, musiques et sons sont indépendants. Chargez la ressource avant de l’utiliser. Les lectures audio continuent pendant les instructions suivantes : `PLAYMUSIC` et `PLAYSOUND` n’attendent pas la fin du son. La musique ne boucle pas par défaut ; configurez `LOOPMUSIC` explicitement. `END` n’arrête pas automatiquement l’audio : utilisez les commandes d’arrêt.

```basic
LOADMUSIC EXEPATH + "Music.ogg", 1
LOOPMUSIC 1, 1
PLAYMUSIC 1
LOADSOUND EXEPATH + "Beep.wav", 1
PLAYSOUND 1
WAITKEY
STOPSOUND 1
STOPMUSIC 1
END
```

## Expressions et fonctions

| Opérateurs | Usage |
| --- | --- |
| `+`, `-`, `*`, `/` | Calculs numériques ; `+` concatène aussi deux chaînes. `+` et `-` peuvent être unaires. |
| `MOD` | Reste de la division : `7 MOD 3`. |
| `POW` | Puissance : `2 POW 3`. |
| `=`, `==`, `<>`, `~=`, `<`, `>`, `<=`, `>=` | Comparaisons. |
| `AND`, `OR`, `XOR`, `NOT` | Opérations logiques. |
| `(`, `)` | Groupement des expressions. |

Les opérateurs respectent les priorités usuelles : puissance, signes unaires, multiplication/division/modulo, addition/soustraction, comparaisons, puis logique. `NOT` porte sur les comparaisons avant `AND`, `XOR` et `OR`. Utilisez des parenthèses pour expliciter une expression ambiguë.

`TRUE` et `ON` valent vrai ; `FALSE` et `OFF` valent faux. Dans une condition, le nombre `0` vaut faux ; les autres nombres valent vrai. `AND` et `OR` évitent d'évaluer leur deuxième opérande lorsque le premier suffit.

| Fonction | Effet |
| --- | --- |
| `ABS(x)` | Valeur absolue. |
| `SIGN(x)` | Signe : -1, 0 ou 1. |
| `SIN(x)`, `COS(x)`, `TAN(x)` | Fonctions trigonométriques ; angles en radians. |
| `ATN(x)` | Arc tangente. |
| `ATN2(y, x)` | Arc tangente tenant compte des deux coordonnées. |
| `ASC(texte)` | Code du premier octet du texte. |
| `CHR(code)` | Caractère correspondant à un code d'octet. |
| `STR(valeur)` | Conversion en texte. |
| `SPACE(n)` | Chaîne de `n` espaces. |
| `STRING(n, texte)` | Répète le texte `n` fois. Un code numérique peut remplacer le texte. |

```basic
x = ABS(-3) + 2 POW 3
PRINT STR(x)
PRINT STRING(4, "*")
END
```

## Conditions

Condition sur une ligne :

```basic
score = 12
IF score >= 10 THEN PRINT "Gagne" ELSE PRINT "Perdu"
END
```

Condition en bloc, avec branches facultatives :

```basic
score = 12
IF score > 10 THEN
    PRINT "Plus de dix"
ELSEIF score = 10 THEN
    PRINT "Dix"
ELSE
    PRINT "Moins de dix"
ENDIF
END
```

La forme sur une ligne accepte une instruction par branche. La forme en bloc accepte plusieurs instructions et des blocs imbriqués.

## Boucles

### FOR / TO / STEP / NEXT

Les bornes sont inclusives. `STEP` est facultatif et vaut 1 par défaut ; il peut être négatif, mais jamais nul. Le nom après `NEXT` est facultatif et doit correspondre à celui du `FOR`.

```basic
FOR i = 1 TO 5 STEP 1
    PRINT i
NEXT i
END
```

### WHILE / WEND

La condition est vérifiée avant chaque passage ; le corps peut ne jamais être exécuté.

```basic
i = 0
WHILE i < 3
    PRINT i
    i = i + 1
WEND
END
```

### REPEAT / UNTIL

Le corps est exécuté au moins une fois. La boucle s'arrête lorsque la condition devient vraie.

```basic
i = 0
REPEAT
    i = i + 1
    PRINT i
UNTIL i = 3
END
```

`BREAK` quitte la boucle la plus proche. L'utiliser hors d'une boucle produit une erreur.

## Sauts et sous-programmes

- `GOTO cible` saute vers un numéro de ligne ou un label.
- `GOSUB cible` saute vers une sous-routine et mémorise le point de retour.
- `RETURN` revient après le `GOSUB` correspondant.
- Les labels utilisent la notation `::nom::` et doivent être sur leur propre ligne, ou séparés de l'instruction suivante par `:`.
- Les numéros de ligne et labels doivent être uniques. Une cible inexistante est une erreur.

```basic
10 GOSUB message
20 END
::message::
PRINT "Sous-programme"
RETURN
```

Évitez de sauter directement à l'intérieur d'une boucle `FOR` : son état doit être initialisé par l'instruction `FOR`.

## Limites actuelles

`FUNCTION`, `ENDFUNCTION`, `PROCEDURE` et `ENDPROCEDURE` sont reconnus par le lexer, mais ne sont pas encore pris en charge par le parser et l'interpréteur. Les chaînes longues entre doubles crochets, tableaux et appels de procédures utilisateur ne sont pas pris en charge.

Les chaînes utilisent les fonctions Lua par octets : `ASC` et `CHR` ne sont pas des conversions Unicode. L'interpréteur n'applique pas encore de retour automatique à la ligne ni de défilement du texte dépassant le canvas BASIC.
