import UIKit
import UniformTypeIdentifiers

class ComicImportViewController: UIViewController {
    
    private let comicStorage = ComicStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showImportOptions()
    }
    
    private func setupUI() {
        title = "Import Comics"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Import",
            style: .plain,
            target: self,
            action: #selector(importButtonTapped)
        )
    }
    
    @objc private func importButtonTapped() {
        showImportOptions()
    }
    
    private func showImportOptions() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType(filenameExtension: "cbz")!,
                UTType(filenameExtension: "cbr")!,
                UTType.zip
            ],
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showFolderSelectionForImport(comicURL: URL, coverImageData: Data?, pageCount: Int) {
        let alert = UIAlertController(title: "Choose Folder", message: "Select a folder for '\(comicURL.lastPathComponent)'", preferredStyle: .actionSheet)
        
        // Get actual folders from file system
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let folders = contents.filter { url in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                return isDirectory.boolValue
            }.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            // Option to import to main library (Documents root) - pass nil for folderName
            alert.addAction(UIAlertAction(title: "Main Library", style: .default) { _ in
                self.finalizeImport(comicURL: comicURL, coverImageData: coverImageData, pageCount: pageCount, folderName: nil)
            })
            
            // Options for existing folders - pass folder NAME as String, not URL
            for folderURL in folders {
                alert.addAction(UIAlertAction(title: folderURL.lastPathComponent, style: .default) { _ in
                    self.finalizeImport(comicURL: comicURL, coverImageData: coverImageData, pageCount: pageCount, folderName: folderURL.lastPathComponent)
                })
            }
            
            // Option to create new folder
            alert.addAction(UIAlertAction(title: "Create New Folder", style: .default) { _ in
                self.showCreateNewFolderForImport(comicURL: comicURL, coverImageData: coverImageData, pageCount: pageCount)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            if let popover = alert.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
            
            present(alert, animated: true)
            
        } catch {
            // Fall back to main library (pass nil for folderName)
            finalizeImport(comicURL: comicURL, coverImageData: coverImageData, pageCount: pageCount, folderName: nil)
        }
    }

    private func showCreateNewFolderForImport(comicURL: URL, coverImageData: Data?, pageCount: Int) {
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Folder name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Create & Import", style: .default) { _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            self.finalizeImport(comicURL: comicURL, coverImageData: coverImageData, pageCount: pageCount, folderName: name)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func importComic(from url: URL) {
        let pageCount = ArchiveProcessor.getPageCount(from: url)
        guard pageCount > 0 else {
            showError("Invalid comic file or no pages found.")
            return
        }
        
        let coverImage = ArchiveProcessor.extractCoverImage(from: url)
        let coverImageData = coverImage?.jpegData(compressionQuality: 0.8)
        
        // Show folder selection first
        showFolderSelectionForImport(comicURL: url, coverImageData: coverImageData, pageCount: pageCount)
    }
    
    private func finalizeImport(comicURL: URL, coverImageData: Data?, pageCount: Int, folderName: String?) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        var finalURL = comicURL
        
        // If folder name is provided, create folder and move file
        if let folderName = folderName, !folderName.isEmpty {
            let folderURL = documentsURL.appendingPathComponent(folderName)
            
            // Create physical folder if it doesn't exist
            if !fileManager.fileExists(atPath: folderURL.path) {
                do {
                    try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Created folder: \(folderURL.path)")
                } catch {
                    print("❌ Failed to create folder: \(error)")
                }
            }
            
            // Move file to folder
            let destinationURL = folderURL.appendingPathComponent(comicURL.lastPathComponent)
            
            do {
                // Handle name conflicts
                var finalDestinationURL = destinationURL
                var counter = 1
                while fileManager.fileExists(atPath: finalDestinationURL.path) {
                    let nameWithoutExtension = destinationURL.deletingPathExtension().lastPathComponent
                    let fileExtension = destinationURL.pathExtension
                    let newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
                    finalDestinationURL = folderURL.appendingPathComponent(newName)
                    counter += 1
                }
                
                try fileManager.moveItem(at: comicURL, to: finalDestinationURL)
                finalURL = finalDestinationURL
                print("✅ Moved comic to folder: \(finalDestinationURL.path)")
                
            } catch {
                print("❌ Failed to move file: \(error)")
                // Keep original URL if move fails
            }
        } else {
            // Import to main library - move to Documents root if needed
            let destinationURL = documentsURL.appendingPathComponent(comicURL.lastPathComponent)
            
            // Only move if it's not already in Documents
            if comicURL != destinationURL {
                do {
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.moveItem(at: comicURL, to: destinationURL)
                    finalURL = destinationURL
                } catch {
                    print("❌ Failed to move to main library: \(error)")
                }
            }
        }
        
        // Create comic with final URL
        let comic = ComicBook(
            title: comicURL.deletingPathExtension().lastPathComponent,
            fileURL: finalURL,
            coverImageData: coverImageData,
            totalPages: pageCount
        )
        
        // Save the comic
        var savedComics = comicStorage.loadComics()
        savedComics.append(comic)
        comicStorage.saveComics(savedComics)
        
        print("✅ Successfully imported: \(comic.title)")
    }

    private func createPhysicalFolder(named folderName: String) -> Bool {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created physical folder: \(folderURL.path)")
                return true
            } catch {
                print("❌ Failed to create folder: \(error)")
                return false
            }
        }
        return true
    }

    private func moveFileToFolder(originalURL: URL, folderName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let folderURL = documentsURL.appendingPathComponent(folderName)
        let destinationURL = folderURL.appendingPathComponent(originalURL.lastPathComponent)
        
        do {
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Move the file
            try fileManager.moveItem(at: originalURL, to: destinationURL)
            print("✅ Moved comic to folder: \(destinationURL.path)")
            return destinationURL
            
        } catch {
            print("❌ Failed to move file: \(error)")
            return nil
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Import Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComicImportViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            importComic(from: url)
        }
        
        // Show success message
        let alert = UIAlertController(
            title: "Import Complete",
            message: "Successfully imported \(urls.count) comic(s)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
