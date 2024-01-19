//
//  View+Inspecting.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 19/01/2024.
//

import SwiftUI

// Expose the params from sheet, for testing purpose.
extension View {
    func inspectableSheet<Item, Sheet>(item: Binding<Item?>,
                                       onDismiss: (() -> Void)? = nil,
                                       content: @escaping (Item) -> Sheet)
    -> some View where Item: Identifiable, Sheet: View {
        modifier(InspectableSheetWithItem(item: item, onDismiss: onDismiss, popupBuilder: content))
    }
}

struct InspectableSheetWithItem<Item, Sheet>: ViewModifier where Item: Identifiable, Sheet: View {
    let item: Binding<Item?>
    let onDismiss: (() -> Void)?
    let popupBuilder: (Item) -> Sheet
    
    func body(content: Self.Content) -> some View {
        content.sheet(item: item, onDismiss: onDismiss, content: popupBuilder)
    }
}
