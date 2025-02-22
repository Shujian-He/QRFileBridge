//
//  ContentView.swift
//  QRFileBridge
//
//  Created by Shujian He on 21/02/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("QR To File", systemImage: "qrcode") {
                QRToFileView()
            }
            
            Tab("File To QR", systemImage: "folder") {
                FileToQRView()
            }
        }
    }
}

#Preview {
    ContentView()
}
