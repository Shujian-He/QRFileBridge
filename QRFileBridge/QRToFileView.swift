//
//  QRToFileView.swift
//  QRFileBridge
//
//  Created by Shujian He on 21/02/2025.
//

import SwiftUI
import CodeScanner
import AVFoundation

struct QRToFileView: View {
    // MARK: - State Properties
    @State private var isPresentingScanner = false
    @State private var headerReceived = false
    @State private var fileName: String = ""
    @State private var fileSize: Int = 0
    @State private var totalSegments: Int = 0
    @State private var segments: [Int: Data] = [:]
    @State private var statusMessage: String = "Please scan the header QR code."
    
    var body: some View {
        VStack(spacing: 10) {
            // Status message to inform the user.
            if headerReceived {
                // Optionally, display progress of received segments.
                Text(statusMessage + "\nReceived \(segments.count) of \(totalSegments) segments.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .drawingGroup() // disable stupid animation
            } else {
                Text(statusMessage)
                    .multilineTextAlignment(.center)
                    .padding()
                    .drawingGroup() // disable stupid animation
            }
            
            // Show the scanner view if needed.
            if isPresentingScanner {
                CodeScannerView(codeTypes: [.qr],
                                scanMode: .oncePerCode,
                                scanInterval: 0,
                                showViewfinder: true,
                                simulatedData: "",
                                videoCaptureDevice: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                                completion: handleScan)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
            }
            
            // Button to start scanning.
            if !isPresentingScanner {
                Button(action: {
                    isPresentingScanner = true
                }) {
                    Text("Scan QR Code")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .drawingGroup() // disable stupid animation
            } else {
                Button(action: {
                    isPresentingScanner = false
                }) {
                    Text("Close Camera")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .drawingGroup() // disable stupid animation
            }
            
            Button(action: {
                resetScanning()
                statusMessage = "Please scan the header QR code."
            }) {
                Text("Reset")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .drawingGroup() // disable stupid animation
            
            // When all segments have been received, show the "Save File" button.
            if headerReceived && segments.count == totalSegments && totalSegments > 0 {
                Button(action: {
                    reconstructFile()
                }) {
                    Text("Save File")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .drawingGroup() // disable stupid animation
            }
            
//            Spacer()
        }
        .padding()
    }
    
    // MARK: - QR Code Handling
    func handleScan(result: Result<ScanResult, ScanError>) {
        // Hide scanner view after a scan.
//        isPresentingScanner = false
        
        switch result {
        case .success(let scanResult):
            let code = scanResult.string
            processScannedCode(code)
        case .failure(let error):
            statusMessage = "Scanning failed: \(error.localizedDescription)"
        }
    }
    
    func processScannedCode(_ code: String) {
        // Check if the scanned code is a header.
        if code.hasPrefix("HEADER:") {
            // Expected format: HEADER:fileName:fileSize:numQRs
            let parts = code.split(separator: ":")
            guard parts.count == 4 else {
                statusMessage = "Invalid header format."
                return
            }
            headerReceived = true
            fileName = String(parts[1])
            if let size = Int(parts[2]), let total = Int(parts[3]) {
                fileSize = size
                totalSegments = total
                statusMessage = "Header received:\nFile: \(fileName)\nSize: \(fileSize) bytes\nExpecting \(totalSegments) data segments."
            } else {
                statusMessage = "Header contains invalid numbers."
            }
        } else {
            // Must process header before others.
            guard headerReceived else {
                statusMessage = "Header not scanned yet."
                return
            }
            // Process a data QR code.
            // The QR code contains a base64 encoded string of [2-byte sequence number][chunk data].
            guard let decodedData = Data(base64Encoded: code) else {
                statusMessage = "Failed to decode base64 data."
                return
            }
            // Ensure there are at least 2 bytes for the sequence number.
            guard decodedData.count > 2 else {
                statusMessage = "Scanned data is too short."
                return
            }
            
            // Extract the first 2 bytes for the sequence number (big-endian).
            let seqNumData = decodedData.prefix(2)
            let sequenceNumber = seqNumData.withUnsafeBytes {
                Int($0.load(as: UInt16.self).bigEndian)
            }
            
            // Ensure the sequence number in range.
            guard sequenceNumber >= 1 && sequenceNumber <= totalSegments else {
                statusMessage = "Invalid sequence number."
                return
            }
            
            // The remaining bytes are the actual chunk.
            let chunkData = decodedData.dropFirst(2)
            
            // Only add if this segment hasn't been received yet.
            if segments[sequenceNumber] == nil {
                segments[sequenceNumber] = Data(chunkData)
                statusMessage = "Received segment \(sequenceNumber) of \(totalSegments)."
            } else {
                statusMessage = "Segment \(sequenceNumber) already scanned."
            }
            
            // Check if we now have all the segments.
            if segments.count == totalSegments {
                statusMessage = "All segments received!\nYou can now save the file."
            }
        }
    }
    
    // MARK: - File Reconstruction
    func reconstructFile() {
        guard headerReceived else {
            statusMessage = "Header not scanned yet."
            return
        }
        guard segments.count == totalSegments else {
            statusMessage = "Missing segments.\n\(segments.count) out of \(totalSegments) received."
            return
        }
        
        print(segments as Any)
        
        // Assemble file data by ordering the segments.
        var fileData = Data()
        for i in 1..<(totalSegments + 1) {
            guard let segment = segments[i] else {
                statusMessage = "Missing segment \(i)."
                return
            }
            fileData.append(segment)
        }
        
        guard fileData.count == fileSize else {
            statusMessage = "Error: Reconstructed file size (\(fileData.count)) does not match file size (\(fileSize)) in header."
            return
        }
        
        // Save the reconstructed file to the app's documents directory.
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileData.write(to: fileURL)
            statusMessage = "File saved to:\n\(fileURL.path)"
        } catch {
            statusMessage = "Failed to save file: \(error.localizedDescription)"
        }
        
        resetScanning()
    }
    
    func resetScanning() {
        isPresentingScanner = false
        headerReceived = false
        fileName = ""
        fileSize = 0
        totalSegments = 0
        segments = [:]
    }
}

#Preview {
    QRToFileView()
}
