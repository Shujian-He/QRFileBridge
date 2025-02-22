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
                
//                .defaultScrollAnchor(.center)
            }
            
            Tab("File To QR", systemImage: "folder") {
                
                FileToQRView()
                
//                .defaultScrollAnchor(.center)
            }
        }
        .defaultScrollAnchor(.center)
    }
}

#Preview {
    ContentView()
}
