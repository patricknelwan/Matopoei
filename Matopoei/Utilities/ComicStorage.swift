import Foundation

class ComicStorage {
    private let userDefaults = UserDefaults.standard
    private let comicsKey = "SavedComics"
    
    func saveComics(_ comics: [ComicBook]) {
        do {
            let data = try JSONEncoder().encode(comics)
            userDefaults.set(data, forKey: comicsKey)
        } catch {
            print("Failed to save comics: \(error)")
        }
    }
    
    func loadComics() -> [ComicBook] {
        guard let data = userDefaults.data(forKey: comicsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([ComicBook].self, from: data)
        } catch {
            print("Failed to load comics: \(error)")
            return []
        }
    }
    
    func clearAll() {
        userDefaults.removeObject(forKey: comicsKey)
    }
}
