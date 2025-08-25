//
//  MainAppVIew.swift
//  DatabaseManager
//
//  Created by thierryH24 on 24/08/2025.
//

import SwiftUI
import SwiftData
import Combine


// MARK: - Vue principale de l'app
struct MainAppView: View {

    @EnvironmentObject var containerManager: ContainerManager
    @State private var isDarkMode = false

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack {
                HStack {
                    Text(containerManager.currentDatabaseName)
                        .font(.headline)
                    Spacer()
                    
                    Menu {
                        Button("Close") {
                            containerManager.closeCurrentDatabase()
                        }
                        Button("Show in Finder") {
                            if let url = containerManager.currentDatabaseURL {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding()
                
                Divider()
                
                Text("Contents of the database")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .frame(minWidth: 200)
            
        } detail: {
            // Contenu principal
            if let container = containerManager.currentContainer {
                PersonListView()
                    .modelContainer(container)
                    .navigationTitle("Persons")
            } else {
                Text("No database is open")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    containerManager.closeCurrentDatabase()
                } label: {
                    Label("Home", systemImage: "house")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    isDarkMode.toggle()
                } label: {
                    Label(isDarkMode ? "Light mode" : "Dark mode",
                          systemImage: isDarkMode ? "sun.max" : "moon")
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Vue liste des personnes (simplifiée)
struct PersonListView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddPerson = false
    @State private var newPersonName = ""
    @State private var newPersonAge = 25
    
    @State private var people: [Person] = []

    var body: some View {
        VStack {
            if people.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No person")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Add the first person") {
                        showingAddPerson = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(people) { person in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(person.name)
                                    .font(.headline)
                                Text("\(person.age) years")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(person.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deletePeople)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    showingAddPerson = true
                }
            }
        }
        .onAppear {
            DataContext.shared.context = modelContext
            people = PersonManager.shared.getAllData()
        }
        .sheet(isPresented: $showingAddPerson) {
            AddPersonSheet(
                name: $newPersonName,
                age: $newPersonAge,
                isPresented: $showingAddPerson,
                modelContext: modelContext,
                onAdd: {
                    people = PersonManager.shared.getAllData()
                }
            )
        }
    }
    
    private func deletePeople(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(people[index])
            }
            try? modelContext.save()
        }
    }
}

