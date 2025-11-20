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
                        Button(String(localized: "Close",table: "MainApp")) {
                            containerManager.closeCurrentDatabase()
                        }
                        Button(String(localized: "Show in Finder",table: "MainApp")) {
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
                Text(String(localized: "Contents of the database",table: "MainApp"))
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
                    .navigationTitle(String(localized: "Persons"))
            } else {
                Text(String(localized: "No database is open",table: "MainApp"))
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    containerManager.closeCurrentDatabase()
                } label: {
                    Label(String(localized: "Home",table: "MainApp"), systemImage: "house")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    isDarkMode.toggle()
                } label: {
                    Label(isDarkMode ? String(localized: "Light mode",table: "MainApp") : String(localized: "Dark mode",table: "MainApp"),
                          systemImage: isDarkMode ? "sun.max" : "moon")
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// MARK: - Vue liste des personnes (simplifiée)
struct PersonListView: View {
    
    @Environment(\.modelContext) private var modelContext1
//    @Environment(\.undoManager) private var undoManager
    
    @State var modelContext : ModelContext?
    @State var undoManager : UndoManager?

    @State private var newPersonName = ""
    @State private var newPersonAge = 25
    
    @State private var peoples: [Person] = []
    @State private var selectedItem: Person.ID?
    @State private var sortOrder = [KeyPathComparator(\Person.name)]
    
    @State private var lastDeletedID: Person.ID?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var isModeCreate = false
    
    // Fiche détail
    @State private var showingDetail = false
    @State private var detailPerson: Person?
    
    var manager : UndoManager? {
        UndoManager()
    }
    var canUndo : Bool {
        undoManager?.canUndo ?? false
    }
    var canRedo : Bool {
        undoManager?.canRedo ?? false
    }
    
    var body: some View {
        VStack {
            if peoples.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text(String(localized: "No person",table: "MainApp"))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(String(localized: "Add the first person",table: "MainApp")) {
                        isAddDialogPresented = true
                        isModeCreate = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(peoples, selection: $selectedItem, sortOrder: $sortOrder, columns: {
                    TableColumn(String(localized: "Name",table: "MainApp"), value: \.name)
                    TableColumn(String(localized: "Town",table: "MainApp"), value: \.town)
                    TableColumn(String(localized: "Age",table: "MainApp")) { person in
                        Text("\(person.age)")
                    }
                    TableColumn(String(localized: "CreateAt",table: "MainApp")) { person in
                        Text("\(person.createdAt, style: .date)")
                    }
                })
                .onChange(of: sortOrder) { _, newOrder in
                    peoples.sort(using: newOrder)
                }
                .gesture(
                    TapGesture(count: 2).onEnded {
                        openDetailForSelected()
                    }
                )
            }
            HStack {
                UniformLabeledButton(
                    String(localized: "Add",table: "MainApp"),
                    systemImage: "plus",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: .blue
                ) {
                    isAddDialogPresented = true
                    isModeCreate = true
                }
                UniformLabeledButton(
                    String(localized: "Edit",table: "MainApp"),
                    systemImage: "pencil",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: .green
                ) {
                    isEditDialogPresented = true
                    isModeCreate = false
                }
                .disabled(selectedItem == nil)
                
                UniformLabeledButton(
                    String(localized: "Details",table: "MainApp"),
                    systemImage: "info.circle",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: .orange
                ) {
                    // Résoudre l'ID sélectionné vers une Person complète, puis l’assigner
                    if let id = selectedItem {
                        if let person = modelContext?.model(for: id) as? Person {
                            detailPerson = person
                            showingDetail = true
                        } else if let person = peoples.first(where: { $0.id == id }) {
                            // fallback via la liste en mémoire si nécessaire
                            detailPerson = person
                            showingDetail = true
                        }
                    }
                }
                .disabled(selectedItem == nil)
                
                UniformLabeledButton(
                    String(localized: "Delete",table: "MainApp"),
                    systemImage: "trash",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: .red
                ) {
                    delete()
                }
                .disabled(selectedItem == nil)
                
                UniformLabeledButton(
                    String(localized: "Undo",table: "MainApp"),
                    systemImage: "arrow.uturn.backward",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: canUndo ? .yellow : .gray
                ) {
                    if let manager = undoManager, canUndo {
                        manager.undo()
                        peoples = PersonManager.shared.fetchAll()
                    }
                }
                .opacity(canUndo ? 1 : 0.6)
                .allowsHitTesting(canUndo)

                UniformLabeledButton(
                    String(localized: "Redo",table: "MainApp"),
                    systemImage: "arrow.uturn.forward",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: canRedo ? .yellow : .gray
                ) {
                    if let manager = undoManager, canRedo {
                        manager.redo()
                        peoples = PersonManager.shared.fetchAll()
                    }
                }
                .opacity(canRedo ? 1 : 0.6)
                .allowsHitTesting(canRedo)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "Add",table: "MainApp")) {
                    isAddDialogPresented = true
                    isModeCreate = true
                }
            }
        }
        .onAppear {
            modelContext = DataContext.shared.context
            undoManager = DataContext.shared.undoManager
            peoples = PersonManager.shared.fetchAll()
        }
        
        .sheet(isPresented: $isAddDialogPresented,
               onDismiss: {
            // Rafraîchir après création/annulation
            peoples = PersonManager.shared.fetchAll()
        }) {
            PersonFormView(
                isPresented: $isAddDialogPresented,
                isModeCreate: $isModeCreate,
                person: nil
            )
        }
        
        .sheet(isPresented: $isEditDialogPresented,
               onDismiss: {
            // Rafraîchir après édition/annulation
            peoples = PersonManager.shared.fetchAll()
        }) {
            let safePerson = peoples.first(where: { $0.id == selectedItem })
            PersonFormView(
                isPresented: $isEditDialogPresented,
                isModeCreate: $isModeCreate,
                person: safePerson
            )
        }
        
        .sheet(isPresented: $showingDetail, onDismiss: {
            // rafraîchir si des modifications ont eu lieu
            peoples = PersonManager.shared.fetchAll()
        }) {
            let id = selectedItem
            let item = peoples.first(where: { $0.id == id })
            if let person = item {
                PersonDetailView(person: person)
            } else {
                Text(String(localized: "No selection",table: "MainApp"))
                    .padding()
            }
        }
    }
    
    private func openDetailForSelected() {
        guard let id = selectedItem,
              let item = peoples.first(where: { $0.id == id }) else { return }
        detailPerson = item
        showingDetail = true
    }
    
    private func delete() {
        if let id = selectedItem,
           let item = peoples.first(where: { $0.id == id }) {
            lastDeletedID = id
            
            // Suppression via repository (Undo/Redo et save inclus)
            PersonManager.shared.delete(person: item)
            
            DispatchQueue.main.async {
                selectedItem = nil
            }
            // Refetch après mutation
            peoples = PersonManager.shared.fetchAll()
        }
    }
    
    private func deletePeople(offsets: IndexSet) {
        withAnimation {
            // Supprimer via le repository pour chaque index, puis refetch
            let toDelete = offsets.map { peoples[$0] }
            toDelete.forEach { person in
                PersonManager.shared.delete(person: person)
            }
            peoples = PersonManager.shared.fetchAll()
        }
    }
}

