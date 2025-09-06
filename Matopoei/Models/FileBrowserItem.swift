import Foundation

struct FileBrowserItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let dateModified: Date
    let size: Int64?
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            self.dateModified = attributes[.modificationDate] as? Date ?? Date()
            self.size = self.isDirectory ? nil : (attributes[.size] as? Int64 ?? 0)
        } catch {
            self.dateModified = Date()
            self.size = nil
        }
    }
}
