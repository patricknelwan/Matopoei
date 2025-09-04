import ZIPFoundation
import UIKit

class ArchiveProcessor {
    
    static func extractPages(from url: URL) -> [UIImage] {
        print("Attempting to extract pages from: \(url.path)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return []
        }
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "cbz", "zip":
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
            print("Opening ZIP archive at: \(url.path)")
            let archive = try Archive(url: url, accessMode: .read)
            
            // Filter and sort image files
            let imageEntries = archive.filter { entry in
                let pathExtension = URL(fileURLWithPath: entry.path).pathExtension.lowercased()
                let isImage = ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(pathExtension)
                if isImage {
                    print("Found image: \(entry.path)")
                }
                return isImage
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            
            print("Found \(imageEntries.count) image files in archive")
            
            // Extract each image
            for entry in imageEntries {
                var imageData = Data()
                
                _ = try archive.extract(entry) { data in
                    imageData.append(data)
                }
                
                if let image = UIImage(data: imageData) {
                    images.append(image)
                    print("Successfully extracted image: \(entry.path) (\(imageData.count) bytes)")
                } else {
                    print("Failed to create UIImage from data for: \(entry.path)")
                }
            }
        } catch {
            print("Error extracting ZIP archive: \(error)")
        }
        
        print("Total images extracted: \(images.count)")
        return images
    }
    
    private static func extractFromRAR(url: URL) -> [UIImage] {
        // Placeholder for RAR support - implement when UnrarKit is added
        print("RAR support not yet implemented")
        return []
    }
}
