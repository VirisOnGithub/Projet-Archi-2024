<div align="center">
    <h1>Projet : Structure des calculateurs</h1>
    <h4>Clément RENIERS, Julien CHATAIGNER, Luka COUTANT</h4>
</div>


> [!IMPORTANT]
> Ce projet a été réalisé sous Logisim Evolution, et n'est donc pas compatible avec la version classique de Logisim.
> Pour télécharger Logisim Evolution, vous pouvez vous rendre sur le Github du projet : [https://github.com/logisim-evolution/logisim-evolution](https://github.com/logisim-evolution/logisim-evolution)

# Mode d'emploi

- Mettre les instruction dans un fichier de votre choix (que l'on appelera `FichierInput`).
- Exécuter la commande suivante :
```sh
    perl assembleur.pl FichierInput FichierOutput
```
où `FichierOutput` est le fichier où sera écrit le code assembleur généré.
- Ouvrir le circuit dans Logisim Evolution
- Cliquer sur le bouton `Reset` pour initialiser la RAM et éviter les potentiels bugs.
- Faire un clic droit sur le composant `RAM` et cliquer sur "Charger l'image".
- Lancer l'horloge grâce à CTRL+K.

> [!TIP]
> Vous pouvez tester le bon fonctionnement du compilateur et du circuit en utilisant le fichier `input.txt` fourni, qui teste toutes les catégories d'instructions. Si tout se déroule bien, à la fin de l'exécution, le registre $R_0$ devrait contenir la valeur `0x07E8`, qui correspond à 2024 en décimal.

# Instruction disponibles

## UAL

Les instructions de l'UAL sont les suivantes :
- ADD : addition
- SUB : soustraction
- MUL : multiplication
- AND : ET logique
- OR : OU logique
- XOR : OU exclusif logique
- SL : shift logique à gauche
- SR : shift logique à droite
- et toutes leurs variantes immédiates.

> [!TIP]
> Pour les instructions, on utilise la notation assembleur classique :
> $$\text{OP }R_1\text{ }R_2\text{ }R_3 \Longleftrightarrow R_1 = R_2\text{ OP }R_3$$


> [!NOTE]
> Pour le SL/SR, le choix a été porté par l'utilité : faire un shift logique à droite (en remplissant par des 0 à gauche), cela permet de faire une division entière très rapide par $2^n$, et le shift logique à gauche permet de faire une multiplication par $2^n$.
> ```asm
>     ; Division entière par 2^n de la valeur contenue dans le registre R0
>     ;(où n est un entier naturel)
>     SR R0 R0 n
>     ; et c'est tout !
> ```
## Mémoire

Les instructions de la mémoire sont les suivantes :
- LD
- ST

> [!TIP]
> Pour ces instructions, on utilise la syntaxe suivante :
>
> $$
> \begin{align*}
>     \text{LD }R_0\text{ }R_1 &\Longleftrightarrow R_0 := \text{MEM}[R_1] \\
>     \text{ST }R_0\text{ }R_1 &\Longleftrightarrow \text{MEM}[R1] = R_0
> \end{align*}
> $$

## Contrôle

### Saut

L'instuction de saut est la suivante :
- JMP

> [!TIP]
> Pour cette instruction, on utilise la syntaxe suivante :
> 
> $$
>     \text{JMP }LABEL \Longleftrightarrow \text{PC} = R_0
> $$
> 
> où $R_0$ est l'adresse du label `LABEL`.
> 
> Le label peut être n'importe quoi, pourvu qu'il ne contienne ni espace, ni le caractère `:`.

### Strutures conditionnelles

Les structures conditionnelles sont les suivantes :
- JEQU
- JNEQ
- JSUP
- JINF

> [!TIP]
> Pour ces instructions, on utilise la syntaxe suivante :
> 
> $$
>     \text{JEQU }R_0\text{ }R_1\text{ }LABEL \Longleftrightarrow \text{if } R_0 = R_1 \text{ then PC} = R_2
> $$
> 
> où $R_2$ est l'adresse du label `LABEL`.

### Appel de fonction

Les instructions d'appel de fonction sont les suivantes :
- CALL
- RET

> [!TIP]
> Pour ces instructions, on utilise la syntaxe suivante :
> 
> $$
>     \text{CALL }LABEL \Longleftrightarrow \text{PC} = R_0 \\
>     RET
> $$

où $R_0$ est l'adresse du label `LABEL`.

### Arrêt du script

L'instruction d'arrêt du script est la suivante :
- STOP

> [!TIP]
> Cette instruction est appelée sans argument.

# Encodage des instructions

## Encodage global

Chaque instruction est encodée sur 32 bits (de 0 à 31) de la manière suivante (le bit de poids faible est à gauche):

|             | Type d'opération | Opération | Immédiat ? | Registre 1 | Registre 2 | Registre 3 | Vide | Constante (16 bits) |
|-------------|------------------|-----------|------------|------------|------------|------------|------|---------------------|
| Emplacement |       0-1        |    2-4    |     5      |    6-8     |    9-11    |   12-14    |  15  |        16-31        |

Remarque : Bien qu'il y ait toujours une place pour les 3 registres et une constante, les valeurs de ceux-ci ne sont pas toujours utilisées. Dans ce cas, le compilateur met par défaut des 0.
Il en va de même pour le bit 15, jamais utilisé, et du bit immédiat, qui n'est utile qu'à l'UAL.

## Encodage spécifique

<table>
    <thead>
        <tr>
            <th>Type</th>
            <th>OpCode</th>
            <th>Instruction</th>
            <th>Code d'instruction</th>
            <th>Reg1</th>
            <th>Reg2</th>
            <th>Reg3</th>
            <th>Constante</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan=8>UAL</td>
            <td rowspan=8>00</td>
            <td>ADD</td>
            <td>000</td>
            <td rowspan=8>Résultat</td>
            <td rowspan=8>Valeur 1</td>
            <td rowspan=8>Valeur 2</td>
            <td rowspan=8>Valeur2 si immédiat</td>
        </tr>
        <tr>
            <td>SUB</td>
            <td>001</td>
        </tr>
        <tr>
            <td>MUL</td>
            <td>010</td>
        </tr>
        <tr>
            <td>AND</td>
            <td>011</td>
        </tr>
        <tr>
            <td>OR</td>
            <td>100</td>
        </tr>
        <tr>
            <td>XOR</td>
            <td>101</td>
        </tr>
        <tr>
            <td>SL</td>
            <td>110</td>
        </tr>
        <tr>
            <td>SR</td>
            <td>111</td>
        </tr>
        <tr>
            <td rowspan=2>MEM</td>
            <td rowspan=2>01</td>
            <td>ST</td>
            <td>000</td>
            <td rowspan=2></td>
            <td rowspan=2></td>
            <td rowspan=2>Adresse</td>
            <td rowspan=2>Valeur</td>
        </tr>
        <tr>
            <td>LD</td>
            <td>001</td>
        </tr>
        <tr>
            <td rowspan=8>CTRL</td>
            <td rowspan=8>11</td>
            <td>JMP</td>
            <td>000</td>
            <td rowspan=6></td>
            <td></td>
            <td></td>
            <td rowspan=6>Adresse</td>
        </tr>
        <tr>
            <td>JSUP</td>
            <td>001</td>
            <td rowspan=4>Valeur 1</td>
            <td rowspan=4>Valeur 2</td>
        </tr>
        <tr>
            <td>JEQU</td>
            <td>010</td>
        </tr>
        <tr>
            <td>JNEQ</td>
            <td>011</td>
        </tr>
        <tr>
            <td>JINF</td>
            <td>100</td>
        </tr>
        <tr>
            <td>CALL</td>
            <td>101</td>
            <td></td>
            <td></td>
        </tr>
        <tr>
            <td>RET</td>
            <td>110</td>
            <td rowspan=2 colspan=4></td>
        </tr>
        <tr>
            <td>STOP</td>
            <td>111</td>
        </tr>
    </tbody>
</table>

> [!NOTE]
> Nous utilisons la valeur `0xffffffff` pour encoder la valeur STOP, afin de bien le voir dans le code hexa.

## Exemple

Codons par exemple l’instruction `SLi R2 R2 3`:

| UAL | SL  | i | R2  | R2  |   | 3                |
|-----|-----|---|-----|-----|---|------------------|
| 00  | 110 | 1 | 010 | 010 |   | 0000000000000011 |

SLi R2 R2 3 sera donc compilé en `00110101001000000000000000000011`, où les 4 bits non utilisés ont été remplacés par des 0.

> [!WARNING]
> En réalité, Logisim affiche le bit de poids faible à droite contrairement à nous et affiche le tout en hexadécimal plutôt qu’en binaire, donc l’instruction donnerait plutôt :
> 
> | 3                | R2  | R2  | i | SL  | UAL |
> |------------------|-----|-----|---|-----|-----|
> | 0000000000000011 | 010 | 010 | 1 | 110 | 00  |
> 
> Donc le compilateur ressortira `00000000000000110000010010111000`, ce qui donne en hexadécimal `0x000304b8`.

# Architecture du circuit

Le haut du circuit contient la clock principale, qui fait alterner le circuit entre le mode Fetch et Exec, ainsi que les valeurs des principaux registres.  
Le registre PC contient l’adresse de l’instruction à exécuter tandis que le registre IR contient l’instruction à exécuter.  
Durant la phase Fetch, l’instruction est chargée en mémoire, tandis que durant la phase Exec, elle est exécutée.  

- Seq :
Fait alterner le circuit entre Fetch et Exec, jusqu’à la première instruction STOP.
-  Registres :
Contient les 8 registres du processeur. En fonction de l’instruction, il les met à jours, récupère leurs valeurs, ou les deux à la fois. Ce qu’on a appelé Registre1, Registre2, et Registre3 plus tôt correspondent respectivement à DR, SR1, et SR2.
- UAL :
Effectue les opérations de type UAL et renvoie le résultat dans les registres.
- GetCst :
Indique à l’UAL si l’opération est immédiate ou non.
- DecodeIR :
Lit l’instruction stockée dans IR afin d’indiquer au reste du circuit quel type d’opération est en cours d’exécution. Il récupère également l’adresse en cas d’instruction CTRL.
- Comp :
Lorsqu’une instruction CTRL est effectuée, il vérifie si les conditions du JMP sont réunis. S’il n’y a pas de conditions (JMP normal), il est vrai par défaut.
- RegPC :
Contient le registre PC et a pour charge de le changer durant la phase Exec. S’il y a un jump et si la condition du jump est vérifiée, il remplace PC par cette adresse, sinon il l’incrémente juste de 1.
- GetAddr :
Choisis l’adresse mémoire qui est donnée à la RAM. En temps normal, il donne juste PC, mais si une instruction MEM est en cours d’exécution il donne l’adresse nécessaire.
- RamCtrl :
Spécifie à la RAM le comportement qu’elle doit avoir (si elle doit être lue ou écrite dedans).


# Compilateur

Le compilateur a été écrit en Perl. En effet, c'est un langage recommandé pour le traitements des chaînes de caractères et des fichiers textes.
 < FichierInput > FichierOutput
## Utilisation du compilateur

Le compilateur accepte deux syntaxes :
```sh
    perl assembleur.pl FichierInput FichierOutput
```
ou
```sh
    perl assembleur.pl
```
> [!IMPORTANT]
> Dans ce deuxième cas, les noms par défaut sont `input.txt` et `output.txt`.

## Fonctionnement du compilateur

> [!IMPORTANT]
> Cette section est une explication sommaire du fonctionnement du compilateur. Pour plus de détails, vous pouvez consulter le code source.

### Les hashmaps

Dans le langage donné, chaque instruction donne lieu à un unique code (par exemple l'instruction `ADD` donnera lieu à un code `000`). 
Ainsi, l'usage des hashmaps permet de faire correspondre chaque instruction à son code.
Par ailleurs, les hashmaps ont aussi une autre utilité : elles permettent de tester à quelle catégorie appartient l'instruction (UAL, MEM, CTRL) : par exemple, l'instruction :

```perl
my %opCTRL = map { $_ => 1 } ( 
    "JMP", "JEQU", "JNEQ", "JSUP", "JINF", "CALL", "RET", "STOP" 
);
```

crée une hasmap qui a pour clés les instructions de contrôle, et pour valeur 1 pour chaque. Ainsi on peut tester si une instruction est de contrôle en faisant :

```perl
if (exists $opCTRL{$op}) {
    # Instruction de contrôle
}
```

### Parcours du fichier

#### Labels

Dans un premier temps, il faut regarder si le fichier contient des labels (cela permet notamment de pouvoir faire appel à une fonction qui est déclarée plus tard dans le code). On les récupère (avec une regex) dans une hashmap, où la clé est le label et la valeur est l'adresse de ce label.

#### Instructions

Enfin, il ne reste plus qu'à parcourir les instructions grâce à l'ensemble du code élaboré précédemment. On récupère les opérations, les registres et les constantes, et on les encode en binaire.
Il suffit ensuite de convertir en hexadécimal par paquets de 8 bits, et d'écrire le tout dans le fichier de sortie, au format correct attendu par le logiciel.

### Messages

Si tout se passe bien, le compilateur affiche un message de succès. 

Sinon, il affiche un message d'erreur, avec le numéro de la ligne où l'erreur a été détectée.

La coloration des messages est faite grâce à un echappement ANSI, qui permet de colorer le texte en rouge, en jaune ou en vert.