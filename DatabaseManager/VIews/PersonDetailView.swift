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
                    Text("Name:")
                        .fontWeight(.medium)
                    Text(person.name)
                }
                GridRow {
                    Text("Town:")
                        .fontWeight(.medium)
                    Text(person.town)
                }
                GridRow {
                    Text("Age:")
                        .fontWeight(.medium)
                    Text("\(person.age)")
                }
                GridRow {
                    Text("Created at:")
                        .fontWeight(.medium)
                    Text(person.createdAt, style: .date)
                }
            }
            
            Spacer()
            
            HStack {
                UniformLabeledButton(
                    "Edit",
                    systemImage: "pencil",
                    minWidth: 120,
                    style: .borderedProminent,
                    tint: .green
                ) {
                    showingEdit = true
                }
                
                UniformLabeledButton(
                    "Delete",
                    systemImage: "trash",
                    minWidth: 120,
                    style: .borderedProminent,
                    tint: .red
                ) {
                    deletePerson()
                }
                
                Spacer()
                
                UniformLabeledButton(
                    "Close",
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
        guard let undoManager else {
            modelContext.delete(person)
            try? modelContext.save()
            dismiss()
            return
        }
        undoManager.beginUndoGrouping()
        undoManager.setActionName("Delete Person")
        modelContext.delete(person)
        undoManager.endUndoGrouping()
        try? modelContext.save()
        dismiss()
    }
}
