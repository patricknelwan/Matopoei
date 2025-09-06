import UIKit

extension UIImage {
    func fused(with rightImage: UIImage?) -> UIImage? {
        guard let rightImage = rightImage else { return self }
        
        let combinedWidth = self.size.width + rightImage.size.width
        let combinedHeight = max(self.size.height, rightImage.size.height)
        let combinedSize = CGSize(width: combinedWidth, height: combinedHeight)
        
        UIGraphicsBeginImageContextWithOptions(combinedSize, false, self.scale)
        
        // Draw left page
        self.draw(in: CGRect(origin: .zero, size: self.size))
        
        // Draw right page next to left page
        rightImage.draw(in: CGRect(origin: CGPoint(x: self.size.width, y: 0), size: rightImage.size))
        
        let fusedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return fusedImage
    }
}


class ComicReaderViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var mainImageView: UIImageView! // Single image view for both modes
    private var pageLabel: UILabel!
    private var toolbar: UIToolbar!
    private var progressView: UIProgressView!
    
    var comic: ComicBook!
    weak var delegate: ComicReaderDelegate?
    
    private var totalPages: Int = 0
    private var currentPageIndex: Int = 0
    private var showingDoublePage: Bool = false
    private var hideControlsTimer: Timer?
    private var isControlsVisible = true
    
    // Reader settings
    private var forceDoublePage: Bool? = nil // nil = auto (follow orientation)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadComicInfo()
        setupGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentPageIndex = comic.currentPageIndex
        updateLayoutForCurrentOrientation()
        resetHideControlsTimer()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayoutForSize(size)
        }, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return !isControlsVisible
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup scroll view with zoom support
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        
        // Setup single image view for both single and double page modes
        mainImageView = UIImageView()
        mainImageView.contentMode = .scaleAspectFit
        mainImageView.backgroundColor = .black
        mainImageView.isUserInteractionEnabled = true
        scrollView.addSubview(mainImageView)
        
        // Setup controls
        setupToolbar()
        setupPageLabel()
        setupProgressView()
    }
    
    private func setupToolbar() {
        toolbar = UIToolbar(frame: CGRect(x: 0, y: view.bounds.height - 44, width: view.bounds.width, height: 44))
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeReader)
        )
        
        let previousButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(previousPage)
        )
        
        let nextButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(nextPage)
        )
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [closeButton, flexibleSpace, previousButton, flexibleSpace, nextButton, flexibleSpace, settingsButton]
        toolbar.tintColor = .white
        toolbar.barTintColor = .black
        toolbar.isTranslucent = true
        view.addSubview(toolbar)
    }
    
    private func setupPageLabel() {
        pageLabel = UILabel(frame: CGRect(x: 0, y: 44, width: view.bounds.width, height: 44))
        pageLabel.autoresizingMask = [.flexibleWidth]
        pageLabel.textColor = .white
        pageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pageLabel.textAlignment = .center
        pageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(pageLabel)
    }
    
    private func setupProgressView() {
        progressView = UIProgressView(frame: CGRect(x: 16, y: view.bounds.height - 88, width: view.bounds.width - 32, height: 4))
        progressView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        progressView.progressTintColor = .white
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        view.addSubview(progressView)
    }
    
    private func setupGestures() {
        // Tap gesture to show/hide controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        // Double tap to zoom
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        tapGesture.require(toFail: doubleTapGesture)
    }
    
    private func loadComicInfo() {
        totalPages = comic.totalPages
        updatePageLabel()
        updateProgress()
    }
    
    private func updateLayoutForCurrentOrientation() {
        let size = view.bounds.size
        updateLayoutForSize(size)
    }
    
    private func updateLayoutForSize(_ size: CGSize) {
        let isLandscape = size.width > size.height
        
        // Determine if we should show double pages
        if let forced = forceDoublePage {
            showingDoublePage = forced
        } else {
            showingDoublePage = isLandscape // Default: single in portrait, double in landscape
        }
        
        configureImageView(for: size)
        loadCurrentPages()
        updatePageLabel()
        updateProgress()
    }
    
    private func configureImageView(for size: CGSize) {
        scrollView.frame = CGRect(origin: .zero, size: size)
        scrollView.zoomScale = 1.0
        
        // Configure the image view to fill the scroll view
        mainImageView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        
        // Make sure we're within bounds
        ensureValidPageIndex()
    }
    
    private func loadCurrentPages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let leftImage = ArchiveProcessor.extractPage(at: self.currentPageIndex, from: self.comic.fileURL)
            
            var finalImage: UIImage?
            
            if self.showingDoublePage && self.currentPageIndex + 1 < self.totalPages {
                // Load right page and fuse with left page
                let rightImage = ArchiveProcessor.extractPage(at: self.currentPageIndex + 1, from: self.comic.fileURL)
                finalImage = leftImage?.fused(with: rightImage)
                
                print("📖 Loaded double page spread: \(self.currentPageIndex + 1)-\(self.currentPageIndex + 2)")
            } else {
                // Single page mode
                finalImage = leftImage
                print("📄 Loaded single page: \(self.currentPageIndex + 1)")
            }
            
            DispatchQueue.main.async {
                self.mainImageView.image = finalImage
                
                // Adjust image view frame to match image aspect ratio while fitting in scroll view
                if let image = finalImage {
                    self.adjustImageViewFrame(for: image)
                }
                
                self.updatePageLabel()
                self.updateProgress()
                
                // Update reading progress
                self.delegate?.didUpdateReadingProgress(for: self.comic, currentPage: self.currentPageIndex)
            }
        }
    }
    
    private func adjustImageViewFrame(for image: UIImage) {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        
        // Calculate the aspect fit frame
        let aspectRatio = imageSize.width / imageSize.height
        let scrollAspectRatio = scrollViewSize.width / scrollViewSize.height
        
        var newFrame: CGRect
        
        if aspectRatio > scrollAspectRatio {
            // Image is wider - fit to width
            let height = scrollViewSize.width / aspectRatio
            newFrame = CGRect(x: 0, y: (scrollViewSize.height - height) / 2, width: scrollViewSize.width, height: height)
        } else {
            // Image is taller - fit to height
            let width = scrollViewSize.height * aspectRatio
            newFrame = CGRect(x: (scrollViewSize.width - width) / 2, y: 0, width: width, height: scrollViewSize.height)
        }
        
        mainImageView.frame = newFrame
        scrollView.contentSize = newFrame.size
    }
    
    private func ensureValidPageIndex() {
        if showingDoublePage {
            // In double page mode, make sure we're on an even page (left page of spread)
            if currentPageIndex % 2 != 0 && currentPageIndex > 0 {
                currentPageIndex -= 1
            }
        }
        
        // Ensure within bounds
        currentPageIndex = max(0, min(currentPageIndex, totalPages - 1))
    }
    
    private func updatePageLabel() {
        if showingDoublePage {
            let rightPageIndex = min(currentPageIndex + 1, totalPages - 1)
            if currentPageIndex + 1 < totalPages {
                pageLabel.text = "Pages \(currentPageIndex + 1)-\(rightPageIndex + 1) of \(totalPages)"
            } else {
                pageLabel.text = "Page \(currentPageIndex + 1) of \(totalPages)"
            }
        } else {
            pageLabel.text = "Page \(currentPageIndex + 1) of \(totalPages)"
        }
    }
    
    private func updateProgress() {
        let progress = totalPages > 0 ? Float(currentPageIndex + 1) / Float(totalPages) : 0
        progressView.setProgress(progress, animated: true)
    }
    
    @objc private func previousPage() {
        if showingDoublePage {
            currentPageIndex = max(0, currentPageIndex - 2)
        } else {
            currentPageIndex = max(0, currentPageIndex - 1)
        }
        
        loadCurrentPages()
        resetHideControlsTimer()
    }
    
    @objc private func nextPage() {
        if showingDoublePage {
            currentPageIndex = min(totalPages - 1, currentPageIndex + 2)
        } else {
            currentPageIndex = min(totalPages - 1, currentPageIndex + 1)
        }
        
        ensureValidPageIndex()
        loadCurrentPages()
        resetHideControlsTimer()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let viewWidth = view.bounds.width
        
        if location.x < viewWidth / 3 {
            // Tap on left - previous page
            previousPage()
        } else if location.x > (2 * viewWidth) / 3 {
            // Tap on right - next page
            nextPage()
        } else {
            // Tap on center - toggle controls
            toggleControls()
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mainImageView)
        
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            // Zoom in to 2x
            let zoomRect = zoomRectForScale(min(scrollView.maximumZoomScale, 2.0), center: location)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            // Zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        
        resetHideControlsTimer()
    }
    
    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(
            width: scrollView.frame.size.width / scale,
            height: scrollView.frame.size.height / scale
        )
        
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
        
        return CGRect(origin: origin, size: size)
    }
    
    private func toggleControls() {
        isControlsVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = self.isControlsVisible ? 1.0 : 0.0
            self.pageLabel.alpha = self.isControlsVisible ? 1.0 : 0.0
            self.progressView.alpha = self.isControlsVisible ? 1.0 : 0.0
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        if isControlsVisible {
            resetHideControlsTimer()
        } else {
            hideControlsTimer?.invalidate()
        }
    }
    
    private func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        guard isControlsVisible else { return }
        
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if self.isControlsVisible {
                self.toggleControls()
            }
        }
    }
    
    @objc private func showSettings() {
        let alert = UIAlertController(title: "Reading Settings", message: nil, preferredStyle: .actionSheet)
        
        // Page layout options
        let currentModeTitle = showingDoublePage ? "Switch to Single Page" : "Switch to Double Page"
        alert.addAction(UIAlertAction(title: currentModeTitle, style: .default) { _ in
            self.forceDoublePage = !self.showingDoublePage
            self.updateLayoutForCurrentOrientation()
        })
        
        alert.addAction(UIAlertAction(title: "Auto Layout (Follow Orientation)", style: .default) { _ in
            self.forceDoublePage = nil
            self.updateLayoutForCurrentOrientation()
        })
        
        alert.addAction(UIAlertAction(title: "Go to Page...", style: .default) { _ in
            self.showPagePicker()
        })
        
        alert.addAction(UIAlertAction(title: "Reset Zoom", style: .default) { _ in
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = toolbar
            popover.sourceRect = toolbar.bounds
        }
        
        present(alert, animated: true)
        resetHideControlsTimer()
    }
    
    private func showPagePicker() {
        let alert = UIAlertController(title: "Go to Page", message: "Enter page number (1-\(totalPages))", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "Page number"
            textField.text = "\(self.currentPageIndex + 1)"
        }
        
        alert.addAction(UIAlertAction(title: "Go", style: .default) { _ in
            guard let text = alert.textFields?.first?.text,
                  let pageNumber = Int(text),
                  pageNumber > 0,
                  pageNumber <= self.totalPages else {
                return
            }
            
            self.currentPageIndex = pageNumber - 1
            self.ensureValidPageIndex()
            self.loadCurrentPages()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func closeReader() {
        dismiss(animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ComicReaderViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image when zoomed
        centerScrollViewContents()
        resetHideControlsTimer()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerScrollViewContents()
    }
    
    private func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = mainImageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        mainImageView.frame = contentsFrame
    }
}
