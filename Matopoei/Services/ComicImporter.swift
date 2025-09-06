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
        print("Document picker selected \(urls.count) files")
        
        var importedComics: [ComicBook] = []
        let fileCoordinator = NSFileCoordinator()
        var error: NSError?
        
        for url in urls {
            print("Processing: \(url.lastPathComponent)")
            
            // Use file coordinator for proper iOS file access
            fileCoordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { (readingURL) in
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileName = readingURL.lastPathComponent
                let permanentURL = documentsDirectory.appendingPathComponent(fileName)
                
                do {
                    // Remove existing file
                    if FileManager.default.fileExists(atPath: permanentURL.path) {
                        try FileManager.default.removeItem(at: permanentURL)
                    }
                    
                    // Copy using file coordinator
                    try FileManager.default.copyItem(at: readingURL, to: permanentURL)
                    print("✅ Successfully copied: \(fileName)")
                    
                    // Use the new efficient methods:
                    let pageCount = ArchiveProcessor.getPageCount(from: permanentURL)
                    let coverImage = ArchiveProcessor.extractCoverImage(from: permanentURL)
                    print("📚 Found \(pageCount) pages")

                    if pageCount > 0 {
                        let coverImageData = coverImage?.jpegData(compressionQuality: 0.8)
                        let title = permanentURL.deletingPathExtension().lastPathComponent
                        
                        let comic = ComicBook(
                            title: title,
                            fileURL: permanentURL,
                            coverImageData: coverImageData,
                            totalPages: pageCount
                        )
                        
                        importedComics.append(comic)
                    }
                } catch {
                    print("❌ Error processing \(fileName): \(error)")
                }
            }
            
            if let error = error {
                print("❌ File coordinator error: \(error)")
            }
        }
        
        // Update UI on main thread
        DispatchQueue.main.async {
            if !importedComics.isEmpty {
                print("🎉 Successfully imported \(importedComics.count) comics")
                self.delegate?.didImportComics(importedComics)
            } else {
                let error = NSError(
                    domain: "ComicImportError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to import comics. Please check file permissions and try again."]
                )
                self.delegate?.didFailToImport(error: error)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}
