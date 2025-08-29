//
//  View.swift
//  DataBaseManager
//
//  Created by thierryH24 on 25/08/2025.
//

import SwiftUI
import AppKit

extension View {
    /// Assure une largeur uniforme entre plusieurs boutons.
    /// - Parameters:
    ///   - minWidth: largeur minimale commune. Par défaut 200.
    ///   - fillContainer: si vrai, le bouton s’étire pour remplir horizontalement son conteneur.
    ///   - controlSize: taille de contrôle AppKit/SwiftUI (regular par défaut).
    ///   - style: style visuel du bouton (nil pour ne rien imposer).
    func uniformButton(
        minWidth: CGFloat = 200,
        fillContainer: Bool = false,
        controlSize: ControlSize = .regular,
        style: ButtonStyleConfiguration.Style? = nil
    ) -> some View {
        modifier(UniformButtonModifier(
            minWidth: minWidth,
            fillContainer: fillContainer,
            controlSize: controlSize,
            style: style
        ))
    }
}

// Petit wrapper pour permettre un style optionnel
private struct UniformButtonModifier: ViewModifier {
    let minWidth: CGFloat
    let fillContainer: Bool
    let controlSize: ControlSize
    let style: ButtonStyleConfiguration.Style?

    func body(content: Content) -> some View {
        let base = content
            .frame(minWidth: minWidth, maxWidth: fillContainer ? .infinity : nil)
            .controlSize(controlSize)

        // Appliquer un style si fourni, sinon renvoyer la vue de base
        if let style {
            switch style {
            case .automatic:
                base.buttonStyle(.automatic)
            case .bordered:
                base.buttonStyle(.bordered)
            case .borderless:
                base.buttonStyle(.borderless)
            case .borderedProminent:
                base.buttonStyle(.borderedProminent)
            case .plain:
                base.buttonStyle(.plain)
            }
        } else {
            base
        }
    }
}

// Aide: refléter les styles standards SwiftUI sous une forme simple à passer
extension ButtonStyleConfiguration {
    enum Style {
        case automatic
        case bordered
        case borderless
        case borderedProminent
        case plain
    }
}
