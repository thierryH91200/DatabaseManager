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
    
    // Fiche détail
    @State private var showingDetail = false
    @State private var detailPerson: Person?

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
                Table(people, selection: $selectedItem, sortOrder: $sortOrder, columns: {
                    TableColumn(String(localized: "Name",table: "MainApp"), value: \.name)
                    TableColumn(String(localized: "Town",table: "MainApp"), value: \.town)
                    TableColumn(String(localized: "Age",table: "MainApp")) { person in
                        Text("\(person.age)")
                    }
                    TableColumn(String(localized: "CreateAt",table: "MainApp")) { person in
                        Text("\(person.createdAt, style: .date)")
                    }
                })
                .onChange(of: sortOrder) { _, newValue in
                    // Optionnel: réappliquer l'ordre local si besoin
                    // Ici, on refetch depuis SwiftData pour rester source-de-vérité
                    people = PersonManager.shared.getAllData()
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
                        if let person = modelContext.model(for: id) as? Person {
                            detailPerson = person
                            showingDetail = true
                        } else if let person = people.first(where: { $0.id == id }) {
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
                    tint: .gray
                ) {
                    if let manager = undoManager, manager.canUndo {
                        manager.undo()
                        people = PersonManager.shared.getAllData()
                    }
                }
                UniformLabeledButton(
                    String(localized: "Redo",table: "MainApp"),
                    systemImage: "arrow.uturn.forward",
                    minWidth: 100,
                    style: .borderedProminent,
                    tint: .gray
                ) {
                    if let manager = undoManager, manager.canRedo {
                        manager.redo()
                        people = PersonManager.shared.getAllData()
                    }
                }
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
            let safePerson = people.first(where: { $0.id == selectedItem })
            PersonFormView(
                isPresented: $isEditDialogPresented,
                isModeCreate: $isModeCreate,
                person: safePerson )
        }
        
        .sheet(isPresented: $showingDetail, onDismiss: {
            // rafraîchir si des modifications ont eu lieu
            people = PersonManager.shared.getAllData()
        }) {
            let id = selectedItem
            let item = people.first(where: { $0.id == id })
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
              let item = people.first(where: { $0.id == id }) else { return }
        detailPerson = item
        showingDetail = true
    }
    
    private func delete() {
        if let id = selectedItem,
           let item = people.first(where: { $0.id == id }) {
            lastDeletedID = id
            
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

