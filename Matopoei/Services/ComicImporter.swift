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
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Extract pages to get total count and cover
                let pages = ArchiveProcessor.extractPages(from: url)
                guard !pages.isEmpty else { continue }
                
                let coverImageData = pages.first?.jpegData(compressionQuality: 0.8)
                let title = url.deletingPathExtension().lastPathComponent
                
                let comic = ComicBook(
                    title: title,
                    fileURL: url,
                    coverImageData: coverImageData,
                    totalPages: pages.count
                )
                
                importedComics.append(comic)
            }
            
            DispatchQueue.main.async {
                self.delegate?.didImportComics(importedComics)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Handle cancellation if needed
    }
}
