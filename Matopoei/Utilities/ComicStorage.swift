import Foundation

class ComicStorage {
    let userDefaults = UserDefaults.standard
    private let comicsKey = "SavedComics"
    private let foldersKey = "ComicFolders"
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    func saveComics(_ comics: [ComicBook]) {
        let comicsForSaving = comics.map { comic in
            ComicBookMetadata(
                id: comic.id,
                title: comic.title,
                fileURL: comic.fileURL,
                currentPageIndex: comic.currentPageIndex,
                totalPages: comic.totalPages,
                dateAdded: comic.dateAdded,
                fileSize: comic.fileSize,
                lastReadDate: comic.lastReadDate
            )
        }

        do {
            let data = try JSONEncoder().encode(comicsForSaving)
            userDefaults.set(data, forKey: comicsKey)
            
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
                    fileSize: metadata.fileSize,
                    lastReadDate: metadata.lastReadDate
                )
            }
        } catch {
            print("Failed to load comics: \(error)")
            return []
        }
    }
    
    // Add folder methods directly here
    func saveFolders(_ folders: [ComicFolder]) {
        do {
            let data = try JSONEncoder().encode(folders)
            userDefaults.set(data, forKey: foldersKey)
        } catch {
            print("Failed to save folders: \(error)")
        }
    }
    
    func loadFolders() -> [ComicFolder] {
        guard let data = userDefaults.data(forKey: foldersKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([ComicFolder].self, from: data)
        } catch {
            print("Failed to load folders: \(error)")
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
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "jpg" && file.lastPathComponent.contains("_cover") {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// UPDATED: ComicBookMetadata with custom decoder for migration
private struct ComicBookMetadata: Codable {
    let id: UUID
    let title: String
    let fileURL: URL
    let currentPageIndex: Int
    let totalPages: Int
    let dateAdded: Date
    let fileSize: Int64
    let lastReadDate: Date

    enum CodingKeys: String, CodingKey {
        case id, title, fileURL, currentPageIndex, totalPages, dateAdded, fileSize, lastReadDate
    }

    // Custom decoder to handle missing lastReadDate in old data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
        currentPageIndex = try container.decode(Int.self, forKey: .currentPageIndex)
        totalPages = try container.decode(Int.self, forKey: .totalPages)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        fileSize = try container.decode(Int64.self, forKey: .fileSize)
        // Use dateAdded as fallback if lastReadDate is missing (for old data)
        lastReadDate = try container.decodeIfPresent(Date.self, forKey: .lastReadDate) ?? dateAdded
    }
    
    // Standard initializer for new data
    init(id: UUID, title: String, fileURL: URL, currentPageIndex: Int, totalPages: Int, dateAdded: Date, fileSize: Int64, lastReadDate: Date) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.currentPageIndex = currentPageIndex
        self.totalPages = totalPages
        self.dateAdded = dateAdded
        self.fileSize = fileSize
        self.lastReadDate = lastReadDate
    }
}
