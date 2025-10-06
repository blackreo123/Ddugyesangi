//
//  FilePickerView.swift
//  Ddugyesangi
//
//  Created by AI Assistant on 2025/10/05.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var selectedFileData: Data?
    @Binding var selectedFileName: String
    @Binding var isPresented: Bool
    
    let supportedTypes: [UTType] = [.jpeg, .png, .pdf, .heic]
    let maxFileSize: Int = 20 * 1024 * 1024 // 20MB
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // 파일에 접근 권한 요청
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ 파일 접근 권한 없음")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let fileData = try Data(contentsOf: url)
                
                // 파일 크기 확인
                if fileData.count > parent.maxFileSize {
                    print("❌ 파일 크기 초과: \(fileData.count) bytes")
                    return
                }
                
                DispatchQueue.main.async {
                    self.parent.selectedFileData = fileData
                    self.parent.selectedFileName = url.lastPathComponent
                    self.parent.isPresented = false
                    print("✅ 파일 선택 완료: \(url.lastPathComponent), \(fileData.count) bytes")
                }
                
            } catch {
                print("❌ 파일 읽기 오류: \(error)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - 파일 선택 버튼 예시
struct FileUploadButton: View {
    @State private var showFilePicker = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String = ""
    @ObservedObject private var aiManager = AIAnalysisManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                showFilePicker = true
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("뜨개질 도안 파일 선택")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // 선택된 파일 정보 표시
            if !selectedFileName.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("선택된 파일:")
                        .font(.headline)
                    Text(selectedFileName)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let fileData = selectedFileData {
                        Text("크기: \(formatFileSize(fileData.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("AI 분석 시작") {
                        if let fileData = selectedFileData {
                            Task {
                                await aiManager.analyzeKnittingPatternFile(
                                    fileData: fileData,
                                    fileName: selectedFileName
                                )
                            }
                        }
                    }
                    .padding(.top, 8)
                    .disabled(selectedFileData == nil || aiManager.isAnalyzing)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePickerView(
                selectedFileData: $selectedFileData,
                selectedFileName: $selectedFileName,
                isPresented: $showFilePicker
            )
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    FileUploadButton()
}