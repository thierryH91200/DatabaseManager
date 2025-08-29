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
    @Environment(\.undoManager) private var undoManager

    @State private var newPersonName = ""
    @State private var newPersonAge = 25
    
    @State private var people: [Person] = []
    @State private var selectedItem: Person.ID?
    @State private var sortOrder = [KeyPathComparator(\Person.name)]
    
    @State private var lastDeletedID: Person.ID?

    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var isModeCreate = false

    var manager : UndoManager? {
        UndoManager()
    }
    var canUndo : Bool? {
        undoManager?.canUndo ?? false
    }
    var canRedo : Bool? {
        undoManager?.canRedo ?? false
    }

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
                        isAddDialogPresented = true
                        isModeCreate = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(people, selection: $selectedItem, sortOrder: $sortOrder, columns: {
                    TableColumn("Name", value: \.name)
                    TableColumn("Age") { person in
                        Text("\(person.age)")
                    }
                    TableColumn("CreateAt") { person in
                        Text("\(person.createdAt, style: .date)")
                    }
                })
                
            }
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    isModeCreate = true
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    isEditDialogPresented = true
                    isModeCreate = false
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil)
                
                Button(action: {
                    delete()
                }) {
                    Label("Delete", systemImage: "trash")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background(Color.red)
//                        .background(selectedItem == nil ? Color.gray : Color.red)
//                        .opacity(selectedItem == nil ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
//                .buttonStyle(.plain)
                .disabled(selectedItem == nil)
                
                Button(action: {
                    if let manager = undoManager, manager.canUndo {
                        manager.undo()
                        people = PersonManager.shared.getAllData()
                    }
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background(canUndo == false ? Color.gray : Color.green)
                        .opacity(canUndo == false  ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                Button(action: {
                    if let manager = undoManager, manager.canRedo {
                        manager.redo()
                        people = PersonManager.shared.getAllData()
                    }
                }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background( canRedo == false ? Color.gray : Color.orange)
                        .opacity( canRedo  == false ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
//                    showingAddPerson = true
                    isAddDialogPresented = true
                    isModeCreate = true
                }
            }
        }
        .onAppear {
            DataContext.shared.context = modelContext
            people = PersonManager.shared.getAllData()
        }

        .sheet(isPresented: $isAddDialogPresented ,
               onDismiss: {
            people = PersonManager.shared.getAllData()})
        {
            PersonFormView(
                isPresented: $isAddDialogPresented,
                isModeCreate: $isModeCreate,
                person: nil )
        }
        
        .sheet(isPresented: $isEditDialogPresented,
               onDismiss: {
            people = PersonManager.shared.getAllData()})
        {
            // Ne passe un Person que s'il est encore valide dans la liste courante
            let safePerson = people.first(where: { $0.id == selectedItem })
            PersonFormView(
                isPresented: $isEditDialogPresented,
                isModeCreate: $isModeCreate,
                person: safePerson )
        }
    }
    
    private func delete() {
        if let id = selectedItem,
           let item = people.first(where: { $0.id == id }) {
            lastDeletedID = id
            
//            undoManager = DataContext.shared.undoManager
            
            PersonManager.shared.delete(entity: item, undoManager: undoManager)
            
            DispatchQueue.main.async {
                selectedItem = nil
            }
            people = PersonManager.shared.getAllData()
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

