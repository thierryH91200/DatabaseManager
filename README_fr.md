# DatabaseManager




Gestionnaire moderne pour bases de données SwiftData sur macOS.

<a href="README.md">English</a> | <a href="README_fr.md">Français</a>


<p align="center">
<img src="Doc/Capture1_fr.png" alt="splsh">
<p align="center">
<em>Welcome</em>
</p>
</p>

<p align="center">
<img src="Doc/Capture2_fr.png" alt="main">
<p align="center">
<em>Main</em>
</p>
</p>


## Présentation

**DatabaseManager** est une application macOS permettant de créer, ouvrir et gérer des bases de données au format SwiftData. L’application propose une interface moderne (SwiftUI), la gestion de fichiers récents, et la manipulation d'entités Person (nom, âge, date de création).

## Fonctionnalités

- Création d’une nouvelle base de données SwiftData
- Ouverture de bases existantes
- Liste des fichiers récents
- Ajout, modification, suppression de personnes
- Affichage des informations détaillées (nom, âge, date)
- Réinitialisation des préférences utilisateur
- Support du mode sombre

## Installation

1. Clone ce dépôt :
   ```sh
   git clone <url-du-repo>

Si vous voulez changer de base de données
il est improtant de définir schema à votre convenance
celle ci est défini
dans le fichier "DatabaseManagerApp"

final class AppSchema {
    static let shared = AppSchema()
      
    let schema = Schema([ Person.self])
    
    private init() {}
}


et de créer un CRUD dans votre ModelManager

tout ce qui fait partie du dossier MainAppp fait partide votre application 
le reste fait partie du manager de base
