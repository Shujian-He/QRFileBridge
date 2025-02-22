//
//  FileToQRView.swift
//  QRFileBridge
//
//  Created by Shujian He on 21/02/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

struct FileToQRView: View {
    @State private var fileURL: URL?
    @State private var qrImages: [UIImage] = []
    @State private var fileName: String = ""
    @State private var errorMessage: String = ""
    @State private var isFileImporterPresented = false
    @State private var currentIndex: Int = 0

    // Maximum chunk size
    let MAX_QR_PAYLOAD_SIZE = 2210
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 20) {
            UniversalButton(title: "Select File", backgroundColor: .blue) {
                isFileImporterPresented = true
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !qrImages.isEmpty {
                Text("\(fileName) selected.")
//                    .padding()
                Image(uiImage: qrImages[currentIndex])
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
//                    .padding()
                if currentIndex == 0 {
                    Text("Showing header QR Code")
                } else {
                    Text("Showing \(currentIndex) of \(qrImages.count - 1) data QR Codes")
                }
                HStack {
                    UniversalButton(title: "Previous QR Code", backgroundColor: .blue) {
                        currentIndex = (currentIndex - 1 + qrImages.count) % qrImages.count
                    }
                    UniversalButton(title: "Next QR Code", backgroundColor: .blue) {
                        currentIndex = (currentIndex + 1) % qrImages.count
                    }
                }
                UniversalButton(title: "Reset", backgroundColor: .red, action: reset)
            }
            
        }
        .padding()
        .fileImporter(isPresented: $isFileImporterPresented,
                      allowedContentTypes: [UTType.data],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    fileURL = selectedURL
                    fileName = selectedURL.lastPathComponent
                    generateQRCodes()
                }
            case .failure(let error):
                errorMessage = "Failed to import file: \(error.localizedDescription)"
            }
        }
    }
    
    // Generates a QR code image from a given string using CoreImage.
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        filter.message = data
        filter.correctionLevel = "L"
        if let outputImage = filter.outputImage {
            // Scale up the QR code image.
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    // Converts the file into a header QR and data QR codes.
    func generateQRCodes() {
        qrImages.removeAll()
        errorMessage = ""
        
        guard let fileURL = fileURL,
              let fileData = try? Data(contentsOf: fileURL) else {
            errorMessage = "Could not load file data."
            return
        }
        
        let fileSize = fileData.count
        let numSegments = Int(ceil(Double(fileSize) / Double(MAX_QR_PAYLOAD_SIZE)))
        
        // Create header string in the same format as your Python script.
        let headerString = "HEADER:\(fileName):\(fileSize):\(numSegments)"
        if let headerQR = generateQRCode(from: headerString) {
            qrImages.append(headerQR)
        } else {
            errorMessage = "Failed to generate header QR code."
            return
        }
        
        // Create data QR codes.
        for i in 1...numSegments {
            let start = (i - 1) * MAX_QR_PAYLOAD_SIZE
            let end = min(i * MAX_QR_PAYLOAD_SIZE, fileSize)
            let chunk = fileData.subdata(in: start..<end)
            
            // Prepend a 2-byte big-endian sequence number.
            var seqNum = UInt16(i).bigEndian
            let seqData = withUnsafeBytes(of: &seqNum) { Data($0) }
            let combined = seqData + chunk
            
            // Base64 encode the combined data.
            let base64String = combined.base64EncodedString()
            if let dataQR = generateQRCode(from: base64String) {
                qrImages.append(dataQR)
            } else {
                errorMessage = "Failed to generate QR code for segment \(i)."
                return
            }
        }
    }
    
    func reset() {
        fileURL = nil
        qrImages = []
        fileName = ""
        errorMessage = ""
        currentIndex = 0
    }
}

#Preview {
    FileToQRView()
}
