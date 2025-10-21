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
il est important de définir schema à votre convenance
celle ci est défini dans le fichier "DatabaseManagerApp"

// pour l'incrementation de la build
// https://blog.gingerbeardman.com/2025/06/28/automatic-build-number-incrementing-in-xcode/


Blog   [Increment](https://blog.gingerbeardman.com/2025/06/28/automatic-build-number-incrementing-in-xcode/).


# Mise en place de votre base de données

## 1 - Créer d'abord le fichier Model

```

import SwiftData
import Foundation

@Model
class Book {
    var title: String
    var author: String
    var genre: String?
    
    init(title: String, author: String, genre: String? = nil) {
        self.title = title
        self.author = author
        self.genre = genre
    }
}
```

## 2 - Créer un CRUD dans votre ModelManager

```
@MainActor
@Observable
final class BookManager {
    
    static let shared = BookManager()
    var books: [Book] = []
    
    private var modelContext: ModelContext? { DataContext.shared.context }
    private var undoManager: UndoManager? { DataContext.shared.undoManager }

    private init () {}
    
    func reset() {
        books.removeAll()
    }
    // MARK: - Create
    func create(title: String, author: String, genre: String) -> Book? {
        let book = Book(title: title, author: author, genre: genre)
        guard let context = modelContext else {
            print("ModelContext missing in create(); returning unsaved Person.")
            return nil
        }
        context.insert(book)
        
        do {
            try context.save()
        } catch {
            print("Error saving after create Person: \(error.localizedDescription)")
        }
        return book
    }
    
    // MARK: - Read
    func readAll(sortedBy sortDescriptors: [SortDescriptor<Book>] = [SortDescriptor(\Book.author, order: .forward)]) -> [Book] {
        guard let context = modelContext else {
            print("ModelContext missing in fetchAll(); returning empty list.")
            return []
        }
        
        let descriptor = FetchDescriptor<Book>(
            predicate: nil,
            sortBy: sortDescriptors
        )
        do {
            books =  try context.fetch(descriptor)
        } catch {
            print("Error fetching Persons: \(error.localizedDescription)")
            return []
        }
        return books
    }

    
    // MARK: - Update
    func update(book: Book, title: String, author: String, genre: String) {
        guard let context = modelContext else {
            print("ModelContext missing in update(); aborting.")
            return
        }
        let oldTitle = book.title
        let oldAuthor = book.author
        let oldGenre  = book.genre
                
        book.title = title
        book.author = author
        book.genre  = genre
                
        do {
            try context.save()
        } catch {
            print("Error saving after update Person: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete
    func delete(person: Person) {
        guard let context = modelContext else {
            print("ModelContext missing in delete(); aborting.")
            return
        }
                
        do {
            try context.save()
        } catch {
            print("Error saving after delete Person: \(error.localizedDescription)")
        }
    }
}
```

## 3 - Dans le fichier DatabaseManagerApp
```
final class AppSchema {
    static let shared = AppSchema()
      
    let schema = Schema([ Book.self])
    
    private init() {}
}
```
# Important
Tout ce qui fait partie du dossier MainAppp fait parti de votre application 
le reste fait partie du manager de base
