//
//  Book.swift
//  DataBaseManager
//
//  Created by thierryH24 on 21/10/2025.
//

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
            print("ModelContext missing in readAll(); returning empty list.")
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
