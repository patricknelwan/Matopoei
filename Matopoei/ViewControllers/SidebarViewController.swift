import UIKit

enum SidebarSection: Int, CaseIterable {
    case main = 0
    
    var title: String {
        switch self {
        case .main: return "Main"
        }
    }
}

enum MainMenuItem: Int, CaseIterable {
    case readingNow = 0
    case library = 1
//    case importComics = 2
    
    var title: String {
        switch self {
        case .readingNow: return "Reading Now"
        case .library: return "All Comics"
//        case .importComics: return "Import Comics"
        }
    }
    
    var icon: String {
        switch self {
        case .readingNow: return "book.fill"
        case .library: return "books.vertical.fill"
//        case .importComics: return "plus.circle.fill"
        }
    }
}

class SidebarViewController: UIViewController {
    
    private var tableView: UITableView!
    private let comicStorage = ComicStorage()
//    private var folders: [FileBrowserItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        loadDirectories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadDirectories()
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "Matopoei"
        view.backgroundColor = .systemBackground
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SidebarCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FolderCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showLibrary(folderURL: URL? = nil) {
        let libraryVC = LibraryViewController(folderURL: folderURL)
        presentDetailViewController(libraryVC)
    }
    
    private func showReadingNow() {
        let readingNowVC = ReadingNowViewController()
        presentDetailViewController(readingNowVC)
    }
    
    private func showImport() {
        let importVC = ComicImportViewController()
        presentDetailViewController(importVC)
    }
    
    private func presentDetailViewController(_ viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        splitViewController?.setViewController(navController, for: .secondary)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SidebarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MainMenuItem.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sidebarSection = SidebarSection(rawValue: section) else { return nil }
        return sidebarSection.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarCell", for: indexPath)
        let menuItem = MainMenuItem.allCases[indexPath.row]
        var configuration = cell.defaultContentConfiguration()
        configuration.text = menuItem.title
        configuration.image = UIImage(systemName: menuItem.icon)
        cell.contentConfiguration = configuration
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let menuItem = MainMenuItem.allCases[indexPath.row]
        switch menuItem {
        case .readingNow:
            showReadingNow()
        case .library:
            showLibrary() // All comics
//        case .importComics:
//            showImport()
        }
    }
}
