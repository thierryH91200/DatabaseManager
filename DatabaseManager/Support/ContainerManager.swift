//
//  ContainerManager.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Container Manager avec gestion fichiers récents
class ContainerManager: ObservableObject {
    @Published var currentContainer: ModelContainer?
    @Published var currentDatabaseName: String = ""
    @Published var currentDatabaseURL: URL?
    @Published var recentFiles: [RecentFile] = []
    @Published var showingSplashScreen = true
    
    private let recentFilesKey = "RecentDatabases"
    private let maxRecentFiles = 10
    
    let schema = AppGlobals.shared.schema

    init() {
        loadRecentFiles()
    }
    
    // MARK: - Gestion des fichiers récents
    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: recentFilesKey),
           let files = try? JSONDecoder().decode([RecentFile].self, from: data) {
            // Filtrer les fichiers qui existent encore
            recentFiles = files.filter { FileManager.default.fileExists(atPath: $0.url.path) }
                              .sorted { $0.lastAccessed > $1.lastAccessed }
        }
    }
    
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: recentFilesKey)
        }
    }
    
    private func addToRecentFiles(_ file: RecentFile) {
        // Supprimer le fichier s'il existe déjà
        recentFiles.removeAll { $0.url == file.url }
        
        // Ajouter en première position
        recentFiles.insert(file, at: 0)
        
        // Limiter le nombre de fichiers récents
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        
        saveRecentFiles()
    }
    
    func removeFromRecentFiles(url: URL) {
        recentFiles.removeAll { $0.url == url }
        saveRecentFiles()
    }
    
    // MARK: - Gestion des bases de données
    func createNewDatabase(at url: URL) {

        do {
            // Nettoie l'URL et s'assurer qu'elle a l'extension .store
            var cleanURL = url
            if cleanURL.pathExtension != "store" {
                cleanURL = cleanURL.appendingPathExtension("store")
            }
            
            // Supprime les espaces et caractères problématiques du nom
            let fileName = cleanURL.lastPathComponent
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "\"", with: "")
            
            cleanURL = cleanURL.deletingLastPathComponent().appendingPathComponent(fileName)
            
            print("🔧 Création de la base à: \(cleanURL.path)")
            
            // S'assurer que le dossier parent existe
            let parentDir = cleanURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentDir.path) {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }
            
            // Supprimer le fichier s'il existe déjà
            if FileManager.default.fileExists(atPath: cleanURL.path) {
                try FileManager.default.removeItem(at: cleanURL)
            }
            
            let config = ModelConfiguration(
                schema: schema,
                url: cleanURL,
                allowsSave: true
            )
            
            let container = try ModelContainer(for: schema, configurations: config)
            
            // Ajouter une personne d'exemple
            let context = container.mainContext
            let samplePerson = Person(name: "Exemple", age: 25)
            context.insert(samplePerson)
            
            do {
                try context.save()
                print("✅ L'entité a été sauvée avec succès.")
            } catch {
                print("❌ Erreur lors de la sauvegarde : \(error)")
                let sqliteError = error as NSError
                print("❌ Code SQLite: \(sqliteError.code)")
                print("❌ Détails: \(sqliteError.userInfo)")
            }
            
            // Ouvrir la base créée
            openDatabase(at: cleanURL)
            
        } catch {
            print("❌ Erreur lors de la création : \(error)")
            let sqliteError = error as NSError
            print("❌ Code SQLite: \(sqliteError.code)")
            print("❌ Détails: \(sqliteError.userInfo)")
        }
    }
    
    func openDatabase(at url: URL) {
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: url
            )
            currentContainer = try ModelContainer(for: schema, configurations: config)
            currentDatabaseURL = url
            currentDatabaseName = url.deletingPathExtension().lastPathComponent
            
            // Ajouter aux fichiers récents
            let recentFile = RecentFile(name: currentDatabaseName, url: url)
            addToRecentFiles(recentFile)
            
            // Ferme le splash screen
            showingSplashScreen = false
            
        } catch {
            print("Erreur lors de l'ouverture : \(error)")
        }
    }
    
    func closeCurrentDatabase() {
        currentContainer = nil
        currentDatabaseURL = nil
        currentDatabaseName = ""
        showingSplashScreen = true
    }
}

