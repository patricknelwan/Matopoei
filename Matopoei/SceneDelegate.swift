import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        if #available(iOS 14.0, *) {
            setupModernSidebar()
        } else {
            setupLegacyNavigation()
        }
        
        window?.makeKeyAndVisible()
    }
    
    @available(iOS 14.0, *)
    private func setupModernSidebar() {
        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        splitViewController.preferredSplitBehavior = .tile
        
        // Sidebar (Primary)
        let sidebarVC = SidebarViewController()
        let sidebarNav = UINavigationController(rootViewController: sidebarVC)
        
        // Detail View (Secondary)
        let detailVC = DetailPlaceholderViewController()
        let detailNav = UINavigationController(rootViewController: detailVC)
        
        splitViewController.setViewController(sidebarNav, for: .primary)
        splitViewController.setViewController(detailNav, for: .secondary)
        
        window?.rootViewController = splitViewController
    }
    
    private func setupLegacyNavigation() {
        // Fallback for iOS 13
        let libraryVC = LibraryViewController()
        let nav = UINavigationController(rootViewController: libraryVC)
        window?.rootViewController = nav
    }
}

// MARK: - UISplitViewControllerDelegate
@available(iOS 14.0, *)
extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent the detail view from being shown initially on compact displays
        return true
    }
}
