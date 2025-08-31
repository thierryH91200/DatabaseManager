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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

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
                Text(isModeCreate ? "Add Person" : "Edit Person")
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                HStack {
                    Text("Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Town")
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $town)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("Age")
                        .frame(width: 100, alignment: .leading)
                    TextField("", value: $age, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Spacer()
            }
            .padding()
            .navigationTitle(person == nil ? "New Person" : "Edit Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            modelContext.insert(newItem)
            
            // Undo pour la création
            undoManager?.registerUndo(withTarget: modelContext) { context in
                context.delete(newItem)
            }
        } else if let existingItem = person {
            let oldName = existingItem.name
            let oldTown = existingItem.town
            let oldAge = existingItem.age
            existingItem.name = name
            existingItem.town = town
            existingItem.age = age
            try? modelContext.save()
            // Undo pour la modification
            undoManager?.registerUndo(withTarget: existingItem) { target in
                target.name = oldName
                target.town = oldTown
                target.age = oldAge
                try? modelContext.save()
            }
        }
        onSave?()
        isPresented = false
        dismiss()
    }
    
//    private func updatePerson(_ item: Person) {
//        item.name = name
//        item.town = town
//        item.age = age
//    }
}

