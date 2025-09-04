import Foundation

class ComicStorage {
    private let userDefaults = UserDefaults.standard
    private let comicsKey = "SavedComics"
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func saveComics(_ comics: [ComicBook]) {
        // Save comics metadata without cover image data in UserDefaults
        let comicsForSaving = comics.map { comic in
            ComicBookMetadata(
                id: comic.id,
                title: comic.title,
                fileURL: comic.fileURL,
                currentPageIndex: comic.currentPageIndex,
                totalPages: comic.totalPages,
                dateAdded: comic.dateAdded,
                fileSize: comic.fileSize
            )
        }
        
        do {
            let data = try JSONEncoder().encode(comicsForSaving)
            userDefaults.set(data, forKey: comicsKey)
            
            // Save cover images separately to disk
            for comic in comics {
                saveCoverImage(comic.coverImageData, for: comic.id)
            }
        } catch {
            print("Failed to save comics: \(error)")
        }
    }
    
    func loadComics() -> [ComicBook] {
        guard let data = userDefaults.data(forKey: comicsKey) else {
            return []
        }
        
        do {
            let comicsMetadata = try JSONDecoder().decode([ComicBookMetadata].self, from: data)
            return comicsMetadata.map { metadata in
                ComicBook(
                    id: metadata.id,
                    title: metadata.title,
                    fileURL: metadata.fileURL,
                    coverImageData: loadCoverImage(for: metadata.id),
                    currentPageIndex: metadata.currentPageIndex,
                    totalPages: metadata.totalPages,
                    dateAdded: metadata.dateAdded,
                    fileSize: metadata.fileSize
                )
            }
        } catch {
            print("Failed to load comics: \(error)")
            return []
        }
    }
    
    private func saveCoverImage(_ imageData: Data?, for comicId: UUID) {
        guard let imageData = imageData else { return }
        let imageURL = documentsDirectory.appendingPathComponent("\(comicId.uuidString)_cover.jpg")
        try? imageData.write(to: imageURL)
    }
    
    private func loadCoverImage(for comicId: UUID) -> Data? {
        let imageURL = documentsDirectory.appendingPathComponent("\(comicId.uuidString)_cover.jpg")
        return try? Data(contentsOf: imageURL)
    }
    
    func clearAll() {
        userDefaults.removeObject(forKey: comicsKey)
        
        // Clean up cover images
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "jpg" && file.lastPathComponent.contains("_cover") {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// Separate metadata struct for UserDefaults storage
private struct ComicBookMetadata: Codable {
    let id: UUID
    let title: String
    let fileURL: URL
    let currentPageIndex: Int
    let totalPages: Int
    let dateAdded: Date
    let fileSize: Int64
}
