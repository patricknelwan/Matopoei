import UIKit
import Foundation

struct ComicBook: Identifiable, Codable {
    let id: UUID
    let title: String
    var fileURL: URL
    let coverImageData: Data?
    var currentPageIndex: Int
    let totalPages: Int
    let dateAdded: Date
    let fileSize: Int64
    var lastReadDate: Date
    
    init(title: String, fileURL: URL, coverImageData: Data? = nil, totalPages: Int = 0) {
        self.id = UUID()
        self.title = title
        self.fileURL = fileURL
        self.coverImageData = coverImageData
        self.currentPageIndex = 0
        self.totalPages = totalPages
        self.dateAdded = Date()
        self.lastReadDate = Date()
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            self.fileSize = attributes[.size] as? Int64 ?? 0
        } else {
            self.fileSize = 0
        }
    }
    
    init(id: UUID, title: String, fileURL: URL, coverImageData: Data?, currentPageIndex: Int, totalPages: Int, dateAdded: Date, fileSize: Int64, lastReadDate: Date) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.coverImageData = coverImageData
        self.currentPageIndex = currentPageIndex
        self.totalPages = totalPages
        self.dateAdded = dateAdded
        self.fileSize = fileSize
        self.lastReadDate = lastReadDate
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
