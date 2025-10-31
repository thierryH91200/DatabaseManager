//
//  About.swift
//  DataBaseManager
//
//  Created by thierryH24 on 26/10/2025.
//

import SwiftUI


struct AboutView: View {
    
    private var appName: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
        ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
        ?? "Unknown App"
    }

    var body: some View {
        VStack(spacing: 8) {
            Image("iconDataManager")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48) // réduit
            Text(appName)
                .font(.headline) // plus petit que .title
                .lineLimit(1)
                .truncationMode(.tail)
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            Text("© 2025 " + appName)
                .font(.caption2)
                .lineLimit(1)
            Text("Manage your data with ease!")
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8) // padding réduit
        .frame(minWidth: 72, minHeight: 72) // optionnel: borne mini alignée avec votre defaultSize
    }
}
