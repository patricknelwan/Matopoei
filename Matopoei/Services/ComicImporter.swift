import UIKit
import UniformTypeIdentifiers

protocol ComicImporterDelegate: AnyObject {
    func didImportComics(_ comics: [ComicBook])
    func didFailToImport(error: Error)
}

class ComicImporter: NSObject {
    weak var delegate: ComicImporterDelegate?
    
    func importComics(presentingViewController: UIViewController) {
        let supportedTypes: [UTType] = [
            UTType(filenameExtension: "cbr")!,
            UTType(filenameExtension: "cbz")!,
            UTType.zip
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        picker.modalPresentationStyle = .formSheet
        
        presentingViewController.present(picker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComicImporter: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var importedComics: [ComicBook] = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Create permanent file path in app's documents directory
                let fileName = url.lastPathComponent
                let permanentURL = documentsDirectory.appendingPathComponent(fileName)
                
                do {
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: permanentURL.path) {
                        try FileManager.default.removeItem(at: permanentURL)
                    }
                    
                    // Copy file to permanent location
                    try FileManager.default.copyItem(at: url, to: permanentURL)
                    print("Successfully copied file to: \(permanentURL.path)")
                    
                    // Extract pages from permanent location
                    let pages = ArchiveProcessor.extractPages(from: permanentURL)
                    print("Extracted \(pages.count) pages from \(fileName)")
                    
                    guard !pages.isEmpty else {
                        print("No pages found in \(fileName)")
                        continue
                    }
                    
                    let coverImageData = pages.first?.jpegData(compressionQuality: 0.8)
                    let title = permanentURL.deletingPathExtension().lastPathComponent
                    
                    let comic = ComicBook(
                        title: title,
                        fileURL: permanentURL, // Use permanent URL, not temporary one
                        coverImageData: coverImageData,
                        totalPages: pages.count
                    )
                    
                    importedComics.append(comic)
                    
                } catch {
                    print("Failed to copy file \(fileName): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                if !importedComics.isEmpty {
                    self.delegate?.didImportComics(importedComics)
                } else {
                    let error = NSError(domain: "ComicImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to import any comics. Check file format and try again."])
                    self.delegate?.didFailToImport(error: error)
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}
