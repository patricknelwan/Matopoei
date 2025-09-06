//
//  ComicImportViewController.swift
//  Matopoei
//
//  Created by Patrick Nelwan on 06/09/25.
//


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
    
    private func importComic(from url: URL) {
        let pageCount = ArchiveProcessor.getPageCount(from: url)
        guard pageCount > 0 else {
            showError("Invalid comic file or no pages found.")
            return
        }
        
        let coverImage = ArchiveProcessor.extractCoverImage(from: url)
        let coverImageData = coverImage?.jpegData(compressionQuality: 0.8)
        
        let comic = ComicBook(
            title: url.deletingPathExtension().lastPathComponent,
            fileURL: url,
            coverImageData: coverImageData,
            totalPages: pageCount
        )
        
        // Save the comic
        var savedComics = comicStorage.loadComics()
        savedComics.append(comic)
        comicStorage.saveComics(savedComics)
        
        print("✅ Successfully imported: \(comic.title)")
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
