import UIKit

protocol LibrarySettingsDelegate: AnyObject {
    func didUpdateLibrarySettings(_ settings: LibrarySettings)
}

class LibrarySettingsViewController: UIViewController {
    
    weak var delegate: LibrarySettingsDelegate?
    private let settingsManager = LibrarySettingsManager()
    private var currentSettings: LibrarySettings
    
    private let portraitSlider = UISlider()
    private let landscapeSlider = UISlider()
    private let portraitLabel = UILabel()
    private let landscapeLabel = UILabel()
    private let portraitValueLabel = UILabel()
    private let landscapeValueLabel = UILabel()
    
    init() {
        self.currentSettings = settingsManager.settings
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateLabels()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Library Layout"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetButtonTapped)
        )
        
        setupSliders()
        setupLabels()
        setupLayout()
    }
    
    private func setupSliders() {
        // Portrait slider
        portraitSlider.minimumValue = Float(LibrarySettings.minColumns)
        portraitSlider.maximumValue = Float(LibrarySettings.maxColumns)
        portraitSlider.value = Float(currentSettings.portraitColumns)
        portraitSlider.addTarget(self, action: #selector(portraitSliderChanged), for: .valueChanged)
        
        // Landscape slider
        landscapeSlider.minimumValue = Float(LibrarySettings.minColumns)
        landscapeSlider.maximumValue = Float(LibrarySettings.maxColumns)
        landscapeSlider.value = Float(currentSettings.landscapeColumns)
        landscapeSlider.addTarget(self, action: #selector(landscapeSliderChanged), for: .valueChanged)
    }
    
    private func setupLabels() {
        portraitLabel.text = "Portrait Mode Columns:"
        portraitLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        landscapeLabel.text = "Landscape Mode Columns:"
        landscapeLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        portraitValueLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        portraitValueLabel.textColor = .systemBlue
        portraitValueLabel.textAlignment = .right
        
        landscapeValueLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        landscapeValueLabel.textColor = .systemBlue
        landscapeValueLabel.textAlignment = .right
    }
    
    private func setupLayout() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Portrait section
        let portraitContainer = createSliderContainer(
            label: portraitLabel,
            slider: portraitSlider,
            valueLabel: portraitValueLabel
        )
        
        // Landscape section
        let landscapeContainer = createSliderContainer(
            label: landscapeLabel,
            slider: landscapeSlider,
            valueLabel: landscapeValueLabel
        )
        
        stackView.addArrangedSubview(portraitContainer)
        stackView.addArrangedSubview(landscapeContainer)
        
        // Add preview section
        let previewLabel = UILabel()
        previewLabel.text = "Preview shows current orientation's layout"
        previewLabel.font = UIFont.systemFont(ofSize: 14)
        previewLabel.textColor = .secondaryLabel
        previewLabel.textAlignment = .center
        stackView.addArrangedSubview(previewLabel)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSliderContainer(label: UILabel, slider: UISlider, valueLabel: UILabel) -> UIView {
        let container = UIView()
        
        let topStack = UIStackView(arrangedSubviews: [label, valueLabel])
        topStack.axis = .horizontal
        topStack.distribution = .fillProportionally
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func portraitSliderChanged() {
        currentSettings.portraitColumns = Int(portraitSlider.value)
        updateLabels()
    }
    
    @objc private func landscapeSliderChanged() {
        currentSettings.landscapeColumns = Int(landscapeSlider.value)
        updateLabels()
    }
    
    private func updateLabels() {
        portraitValueLabel.text = "\(currentSettings.portraitColumns)"
        landscapeValueLabel.text = "\(currentSettings.landscapeColumns)"
    }
    
    @objc private func doneButtonTapped() {
        settingsManager.settings = currentSettings
        delegate?.didUpdateLibrarySettings(currentSettings)
        dismiss(animated: true)
    }
    
    @objc private func resetButtonTapped() {
        currentSettings = LibrarySettings.default
        portraitSlider.value = Float(currentSettings.portraitColumns)
        landscapeSlider.value = Float(currentSettings.landscapeColumns)
        updateLabels()
    }
}
