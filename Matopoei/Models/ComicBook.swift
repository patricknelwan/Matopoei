import UIKit
import Foundation

struct ComicBook: Identifiable, Codable {
    let id: UUID
    let title: String
    let fileURL: URL
    let coverImageData: Data?
    var currentPageIndex: Int
    let totalPages: Int
    let dateAdded: Date
    let fileSize: Int64
    
    init(title: String, fileURL: URL, coverImageData: Data? = nil, totalPages: Int = 0) {
        self.id = UUID()
        self.title = title
        self.fileURL = fileURL
        self.coverImageData = coverImageData
        self.currentPageIndex = 0
        self.totalPages = totalPages
        self.dateAdded = Date()
        
        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            self.fileSize = attributes[.size] as? Int64 ?? 0
        } else {
            self.fileSize = 0
        }
    }
    
    var coverImage: UIImage? {
        guard let data = coverImageData else { return nil }
        return UIImage(data: data)
    }
    
    var progressPercentage: Float {
        guard totalPages > 0 else { return 0 }
        return Float(currentPageIndex) / Float(totalPages)
    }
}

enum ComicFormat: String, CaseIterable {
    case cbr = "cbr"
    case cbz = "cbz"
    
    var displayName: String {
        return rawValue.uppercased()
    }
}

enum ComicError: Error {
    case unsupportedFormat
    case corruptedFile
    case noPages
    case accessDenied
}
