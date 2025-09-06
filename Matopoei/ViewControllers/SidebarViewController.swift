import UIKit

enum SidebarSection: Int, CaseIterable {
    case main = 0
    case folders = 1
    
    var title: String {
        switch self {
        case .main: return "Main"
        case .folders: return "My Folders"
        }
    }
}

enum MainMenuItem: Int, CaseIterable {
    case readingNow = 0
    case library = 1
    case importComics = 2
    
    var title: String {
        switch self {
        case .readingNow: return "Reading Now"
        case .library: return "Library"
        case .importComics: return "Import Comics"
        }
    }
    
    var icon: String {
        switch self {
        case .readingNow: return "book.fill"
        case .library: return "books.vertical.fill"
        case .importComics: return "plus.circle.fill"
        }
    }
}

class SidebarViewController: UIViewController {
    
    private var tableView: UITableView!
    private let comicStorage = ComicStorage()
    private var folders: [ComicFolder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFolders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFolders()
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createNewFolder)
        )
    }
    
    private func loadFolders() {
        folders = comicStorage.loadFolders()
    }
    
    @objc private func createNewFolder() {
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Folder name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            let newFolder = ComicFolder(name: name)
            self.folders.append(newFolder)
            self.comicStorage.saveFolders(self.folders)
            self.loadFolders()
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showLibrary(folder: ComicFolder? = nil) {
        let libraryVC = LibraryViewController(folder: folder)
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
    
    // Fix: Renamed method to avoid conflict with UIViewController's method
    private func presentDetailViewController(_ viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        splitViewController?.setViewController(navController, for: .secondary)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SidebarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SidebarSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sidebarSection = SidebarSection(rawValue: section) else { return 0 }
        
        switch sidebarSection {
        case .main:
            return MainMenuItem.allCases.count
        case .folders:
            return folders.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sidebarSection = SidebarSection(rawValue: section) else { return nil }
        return sidebarSection.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sidebarSection = SidebarSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sidebarSection {
        case .main:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SidebarCell", for: indexPath)
            let menuItem = MainMenuItem.allCases[indexPath.row]
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = menuItem.title
            configuration.image = UIImage(systemName: menuItem.icon)
            cell.contentConfiguration = configuration
            
            return cell
            
        case .folders:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
            let folder = folders[indexPath.row]
            
            var configuration = cell.defaultContentConfiguration()
            configuration.text = folder.name
            configuration.image = UIImage(systemName: "folder.fill")
            configuration.secondaryText = "\(folder.comicIds.count) comics"
            cell.contentConfiguration = configuration
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sidebarSection = SidebarSection(rawValue: indexPath.section) else { return }
        
        switch sidebarSection {
        case .main:
            let menuItem = MainMenuItem.allCases[indexPath.row]
            switch menuItem {
            case .readingNow:
                showReadingNow()
            case .library:
                showLibrary()
            case .importComics:
                showImport()
            }
            
        case .folders:
            let folder = folders[indexPath.row]
            showLibrary(folder: folder)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete,
              let sidebarSection = SidebarSection(rawValue: indexPath.section),
              sidebarSection == .folders else { return }
        
        let folder = folders[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Folder",
            message: "Are you sure you want to delete '\(folder.name)'? Comics will be moved to Library.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.folders.remove(at: indexPath.row)
            self.comicStorage.saveFolders(self.folders)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
