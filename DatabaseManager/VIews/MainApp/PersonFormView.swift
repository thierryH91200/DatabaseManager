//
//  PersonFormView.swift
//  WelcomeTo
//
//  Created by thierryH24 on 23/08/2025.
//

import SwiftUI
import SwiftData


// Vue pour la boîte de dialogue d'ajout
struct PersonFormView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.undoManager) private var undoManager
    
    @State var modelContext : ModelContext?
    @State var undoManager : UndoManager?

    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    let person: Person?
    
    var onSave: (() -> Void)?   // callback

    @State private var name: String = ""
    @State private var town: String = ""
    @State private var age: Int = 0

    var body: some View {
        VStack(spacing: 0) { // Spacing à 0 pour que les bandeaux soient collés au contenu
            // Bandeau du haut
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                Text(isModeCreate ? String(localized: "Add Person") : String(localized: "Edit Person"))
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                HStack {
                    Text(String(localized: "Name",table:"MainApp"))
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized: "Town",table:"MainApp"))
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $town)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized: "Age",table:"MainApp"))
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    TextField("", value: $age, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Spacer()
            }
            .padding()
            .navigationTitle(person == nil ? String(localized: "New Person") : String(localized: "Edit Person",table:"MainApp"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel",table:"MainApp")) {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save",table:"MainApp")) {
                        isPresented = false
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.6 : 1)
                }
            }
            .frame(width: 400)
            
            // Bandeau du bas
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
        }
        .onAppear {
            modelContext = DataContext.shared.context
            undoManager = DataContext.shared.undoManager
            
            if let person = person {
                name = person.name
                town = person.town
                age = person.age
            }
        }
    }
    
    private func save() {
        if isModeCreate {
            let newItem = PersonManager.shared.create(name: name, town: town, age: age)
            do {
                try modelContext?.save()
            } catch {
                print("Erreur de sauvegarde SwiftData:", error)
            }

            // Undo pour la création
            undoManager?.registerUndo(withTarget: modelContext!) { context in
                context.delete(newItem)
                do {
                    try modelContext?.save()
                } catch {
                    print("Erreur de sauvegarde SwiftData:", error)
                }
            }
        } else if let existingItem = person {
            let oldName = existingItem.name
            let oldTown = existingItem.town
            let oldAge = existingItem.age
            existingItem.name = name
            existingItem.town = town
            existingItem.age = age
            do {
                try modelContext?.save()
            } catch {
                print("Erreur de sauvegarde SwiftData:", error)
            }
            // Undo pour la modification
            undoManager?.registerUndo(withTarget: existingItem) { target in
                target.name = oldName
                target.town = oldTown
                target.age = oldAge
                do {
                    try modelContext?.save()
                } catch {
                    print("Erreur de sauvegarde SwiftData:", error)
                }
            }
        }
        onSave?()
        isPresented = false
        dismiss()
    }
}

