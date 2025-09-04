import ZIPFoundation
import UIKit

class ArchiveProcessor {
    
    static func extractPages(from url: URL) -> [UIImage] {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "cbz":
            return extractFromZip(url: url)
        case "cbr":
            return extractFromRAR(url: url)
        default:
            print("Unsupported format: \(fileExtension)")
            return []
        }
    }
    
    static func extractCoverImage(from url: URL) -> UIImage? {
        let pages = extractPages(from: url)
        return pages.first
    }
    
    private static func extractFromZip(url: URL) -> [UIImage] {
        var images: [UIImage] = []
        
        do {
            let archive = try Archive(url: url, accessMode: .read)
            
            // Filter and sort image files
            let imageEntries = archive.filter { entry in
                let pathExtension = URL(fileURLWithPath: entry.path).pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(pathExtension)
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            
            // Extract each image
            for entry in imageEntries {
                var imageData = Data()
                
                _ = try archive.extract(entry) { data in
                    imageData.append(data)
                }
                
                if let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
        } catch {
            print("Error extracting ZIP archive: \(error)")
        }
        
        return images
    }
    
    private static func extractFromRAR(url: URL) -> [UIImage] {
        // Placeholder for RAR support - implement when UnrarKit is added
        print("RAR support not yet implemented")
        return []
    }
}
