//
//  Tools.swift
//  QRFileBridge
//
//  Created by Shujian He on 22/02/2025.
//

import SwiftUI

struct UniversalButton: View {
    let title: String
    var backgroundColor: Color = .blue
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .drawingGroup()
    }
}

struct UniversalText: View {
    let title: String
    var backgroundColor: Color = .blue
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
