import UIKit

struct LibrarySettings {
    var portraitColumns: Int
    var landscapeColumns: Int
    
    static let `default` = LibrarySettings(portraitColumns: 2, landscapeColumns: 4)
    
    static let minColumns = 1
    static let maxColumns = 6
    
    var currentColumns: Int {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return portraitColumns
        }
        
        let isLandscape = windowScene.interfaceOrientation.isLandscape
        return isLandscape ? landscapeColumns : portraitColumns
    }
}

class LibrarySettingsManager {
    private let userDefaults = UserDefaults.standard
    private let portraitKey = "LibraryPortraitColumns"
    private let landscapeKey = "LibraryLandscapeColumns"
    
    var settings: LibrarySettings {
        get {
            let portraitColumns = userDefaults.object(forKey: portraitKey) as? Int ?? LibrarySettings.default.portraitColumns
            let landscapeColumns = userDefaults.object(forKey: landscapeKey) as? Int ?? LibrarySettings.default.landscapeColumns
            
            return LibrarySettings(
                portraitColumns: max(LibrarySettings.minColumns, min(LibrarySettings.maxColumns, portraitColumns)),
                landscapeColumns: max(LibrarySettings.minColumns, min(LibrarySettings.maxColumns, landscapeColumns))
            )
        }
        set {
            userDefaults.set(newValue.portraitColumns, forKey: portraitKey)
            userDefaults.set(newValue.landscapeColumns, forKey: landscapeKey)
        }
    }
}
