import ZIPFoundation
import UIKit

class ArchiveProcessor {
    
    // Extract single page by index (most efficient)
    static func extractPage(at index: Int, from url: URL) -> UIImage? {
        print("Extracting page \(index) from: \(url.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return nil
        }
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "cbz", "zip":
            return extractSinglePageFromZip(at: index, url: url)
        case "cbr":
            return nil // Add CBR support later
        default:
            return nil
        }
    }
    
    // Get page count without loading images (NEW METHOD)
    static func getPageCount(from url: URL) -> Int {
        print("Getting page count from: \(url.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return 0
        }
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "cbz", "zip":
            return getPageCountFromZip(url: url)
        case "cbr":
            return 0 // Add CBR support later
        default:
            return 0
        }
    }
    
    // Extract all pages (keep for backward compatibility)
    static func extractPages(from url: URL) -> [UIImage] {
        print("Attempting to extract pages from: \(url.path)")
        
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
    
    // Update extractCoverImage method to be more efficient
    static func extractCoverImage(from url: URL) -> UIImage? {
        print("Extracting cover from: \(url.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File does not exist at path: \(url.path)")
            return nil
        }
        
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "cbz", "zip":
            return extractCoverFromZip(url: url)
        case "cbr":
            return nil // CBR support coming soon
        default:
            return nil
        }
    }

    private static func extractCoverFromZip(url: URL) -> UIImage? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            
            // Get first image file (usually the cover)
            let firstImageEntry = archive.first { entry in
                let pathExtension = URL(fileURLWithPath: entry.path).pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(pathExtension)
            }
            
            guard let coverEntry = firstImageEntry else {
                print("No image files found in archive")
                return nil
            }
            
            var imageData = Data()
            _ = try archive.extract(coverEntry) { data in
                imageData.append(data)
            }
            
            if let image = UIImage(data: imageData) {
                print("✅ Successfully extracted cover: \(coverEntry.path)")
                return image
            } else {
                print("❌ Failed to create UIImage from cover data")
                return nil
            }
            
        } catch {
            print("❌ Error extracting cover: \(error)")
            return nil
        }
    }
    
    // PRIVATE HELPER METHODS
    
    private static func extractSinglePageFromZip(at index: Int, url: URL) -> UIImage? {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            
            let imageEntries = archive.filter { entry in
                let pathExtension = URL(fileURLWithPath: entry.path).pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(pathExtension)
            }.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            
            guard index < imageEntries.count else {
                print("Index \(index) out of range for \(imageEntries.count) pages")
                return nil
            }
            
            let entry = imageEntries[index]
            var imageData = Data()
            
            _ = try archive.extract(entry) { data in
                imageData.append(data)
            }
            
            if let image = UIImage(data: imageData) {
                print("✅ Successfully extracted page \(index): \(entry.path)")
                return image
            } else {
                print("❌ Failed to create UIImage from data for page \(index)")
                return nil
            }
            
        } catch {
            print("❌ Error extracting page \(index): \(error)")
            return nil
        }
    }
    
    private static func getPageCountFromZip(url: URL) -> Int {
        do {
            let archive = try Archive(url: url, accessMode: .read)
            
            let imageCount = archive.filter { entry in
                let pathExtension = URL(fileURLWithPath: entry.path).pathExtension.lowercased()
                return ["jpg", "jpeg", "png", "gif", "webp", "bmp"].contains(pathExtension)
            }.count
            
            print("Found \(imageCount) pages in archive")
            return imageCount
            
        } catch {
            print("Error getting page count from ZIP: \(error)")
            return 0
        }
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
