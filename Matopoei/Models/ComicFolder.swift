import Foundation

struct ComicFolder: Codable, Identifiable {
    let id: UUID
    var name: String
    var comicIds: [UUID]
    let dateCreated: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.comicIds = []
        self.dateCreated = Date()
    }
    
    // Add a comic to this folder
    mutating func addComic(_ comicId: UUID) {
        if !comicIds.contains(comicId) {
            comicIds.append(comicId)
        }
    }
    
    // Remove a comic from this folder
    mutating func removeComic(_ comicId: UUID) {
        comicIds.removeAll { $0 == comicId }
    }
    
    // Check if folder contains a specific comic
    func contains(_ comicId: UUID) -> Bool {
        return comicIds.contains(comicId)
    }
}
