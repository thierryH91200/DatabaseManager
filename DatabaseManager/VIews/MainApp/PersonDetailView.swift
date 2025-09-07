// PersonDetailView.swift
import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    @State var person: Person
    
    @State private var showingEdit = false
    @State private var isModeCreate = false // toujours false ici, on édite
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.title)
                        .fontWeight(.semibold)
                    Text(person.town)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text(String(localized:"Name:",table: "MainApp"))
                        .fontWeight(.medium)
                    Text(person.name)
                }
                GridRow {
                    Text(String(localized:"Town:",table: "MainApp"))
                        .fontWeight(.medium)
                    Text(person.town)
                }
                GridRow {
                    Text(String(localized:"Age:",table: "MainApp"))
                        .fontWeight(.medium)
                    Text("\(person.age)")
                }
                GridRow {
                    Text(String(localized:"Ctrated at:",table: "MainApp"))
                        .fontWeight(.medium)
                    Text(person.createdAt, style: .date)
                }
            }
            
            Spacer()
            
            HStack {
                UniformLabeledButton(
                    String(localized:"Edit",table: "MainApp"),
                    systemImage: "pencil",
                    minWidth: 120,
                    style: .borderedProminent,
                    tint: .green
                ) {
                    showingEdit = true
                }
                
                UniformLabeledButton(
                    String(localized:"Delete",table: "MainApp"),
                    systemImage: "trash",
                    minWidth: 120,
                    style: .borderedProminent,
                    tint: .red
                ) {
                    deletePerson()
                }
                
                Spacer()
                
                UniformLabeledButton(
                    String(localized:"Close",table: "MainApp"),
                    systemImage: "xmark.circle",
                    minWidth: 120,
                    style: .borderedProminent,
                    tint: .orange
                ) {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 300)
        .navigationTitle("Person Details")
        .sheet(isPresented: $showingEdit, onDismiss: {
            // rafraîchir l’état local au besoin (si la référence a changé)
        }) {
            PersonFormView(
                isPresented: $showingEdit,
                isModeCreate: .constant(false),
                person: person
            )
        }
    }
    
    private func deletePerson() {
        // Utilise le repository pour une suppression avec Undo/Redo homogène
        PersonManager.shared.delete(person: person)
        dismiss()
    }
}
