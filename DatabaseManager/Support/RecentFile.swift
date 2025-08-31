//
//  RecentFile.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import SwiftUI
import SwiftData
import Foundation
import Combine
import AppKit
internal import UniformTypeIdentifiers

// MARK: - Structure pour les fichiers récents
struct RecentFile: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: URL
    let lastAccessed: Date
    
    init(id: UUID = UUID(), name: String, url: URL, lastAccessed: Date = Date()) {
        self.id = id
        self.name = name
        self.url = url
        self.lastAccessed = lastAccessed
    }
}

struct SavePanelView: View {
    var onCompletion: (URL?) -> Void
    @State private var panel: NSSavePanel? = nil
    var body: some View {
        Color.clear
            .onAppear {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.store, .sqlite]
                panel.nameFieldStringValue = "Nouvelle Base"
                panel.begin { response in
                    if response == .OK {
                        onCompletion(panel.url)
                    } else {
                        onCompletion(nil)
                    }
                }
            }
    }
}

// MARK: - Row pour fichier récent
struct RecentFileRow: View {
    let recentFile: RecentFile
    @EnvironmentObject var containerManager: ContainerManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recentFile.name)
                    .font(.headline)
                
                Text(recentFile.url.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("Modified: \(recentFile.lastAccessed, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // Vérifier si le fichier existe encore
            if FileManager.default.fileExists(atPath: recentFile.url.path) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            if FileManager.default.fileExists(atPath: recentFile.url.path) {
                containerManager.openDatabase(at: recentFile.url)
            } else {
                containerManager.removeFromRecentFiles(url: recentFile.url)
            }
        }
        .contextMenu {
            if FileManager.default.fileExists(atPath: recentFile.url.path) {
                Button(String(localized: "Open")) {
                    containerManager.openDatabase(at: recentFile.url)
                }
                
                Button(String(localized: "Show in Finder")) {
                    NSWorkspace.shared.activateFileViewerSelecting([recentFile.url])
                }
                
                Divider()
            }
            
            Button(String(localized: "Remove from list"), role: .destructive) {
                containerManager.removeFromRecentFiles(url: recentFile.url)
            }
        }
    }
}

// MARK: - Sheet pour ajouter une personne
struct AddPersonSheet: View {
    @Binding var name: String
    @Binding var town: String
    @Binding var age: Int
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    
    let onAdd: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(String(localized: "Informations")) {
                    TextField(String(localized: "Name"), text: $name)
                    TextField(String(localized: "Town"), text: $town)

                    HStack {
                        Text(String(localized: "Age"))
                        Spacer()
                        TextField(String(localized: "Age"), value: $age, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle(String(localized: "New person"))

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        isPresented = false
                        resetFields()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Add")) {
                        let person = Person(name: name, town: town, age: age)
                        modelContext.insert(person)
                        try? modelContext.save()
                        
                        isPresented = false
                        resetFields()
                        onAdd()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
    
    private func resetFields() {
        name = ""
        town = ""
        age = 25
    }
}

