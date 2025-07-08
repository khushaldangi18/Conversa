//
//  SharedComponents.swift
//  Chatora
//
//  Created by FCP 21 on 08/07/25.
//

import SwiftUI

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}
