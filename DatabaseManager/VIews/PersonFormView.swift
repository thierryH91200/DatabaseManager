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
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    let person: Person?
//    let url: URL?
    
    var onSave: (() -> Void)?   // callback

    @State private var name: String = ""
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
                age = person.age
            }
        }
    }
    
    private func save() {
//        guard let url = url else { return }
        if isModeCreate { // Création

            let newItem = PersonManager.shared.create(
                name: name,
                age: age
            )
            modelContext.insert(newItem)
            try? modelContext.save()

        } else { // Modification
            if let existingItem = person {
                existingItem.name = name
                existingItem.age = age

                try? modelContext.save()
            }
        }
        onSave?()
        isPresented = false
        dismiss()
    }
    
    private func updatePerson(_ item: Person) {
        item.name = name
        item.age = age
    }
}

