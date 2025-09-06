import UIKit

class ComicReaderViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var pageLabel: UILabel!
    private var toolbar: UIToolbar!
    private var progressView: UIProgressView!
    
    var comic: ComicBook!
    weak var delegate: ComicReaderDelegate?
    
    // Don't store all pages - load on demand
    private var totalPages: Int = 0
    private var currentPageIndex: Int = 0
    private var hideControlsTimer: Timer?
    private var isControlsVisible = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadComicInfo() // Only load page count, not all pages
        setupGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentPageIndex = comic.currentPageIndex
        loadCurrentPage() // Load only current page
        resetHideControlsTimer()
    }
    
    override var prefersStatusBarHidden: Bool {
        return !isControlsVisible
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup scroll view
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        
        // Setup image view
        imageView = UIImageView(frame: scrollView.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .black
        scrollView.addSubview(imageView)
        
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
        
        // Swipe gestures for page navigation
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextPage))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousPage))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    // FIXED: Load comic info only, not all pages
    private func loadComicInfo() {
        totalPages = comic.totalPages
        updatePageLabel()
        updateProgress()
    }
    
    // FIXED: Load only the current page
    private func loadCurrentPage() {
        guard currentPageIndex >= 0 && currentPageIndex < totalPages else { return }
        
        print("Loading page \(currentPageIndex + 1) of \(totalPages)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Extract only the current page
            let pageImage = ArchiveProcessor.extractPage(at: self.currentPageIndex, from: self.comic.fileURL)
            
            DispatchQueue.main.async {
                if let image = pageImage {
                    self.imageView.image = image
                    print("✅ Successfully loaded page \(self.currentPageIndex + 1)")
                } else {
                    print("❌ Failed to load page \(self.currentPageIndex + 1)")
                }
                
                self.updatePageLabel()
                self.updateProgress()
                self.resetZoom()
                
                // Update reading progress
                self.delegate?.didUpdateReadingProgress(for: self.comic, currentPage: self.currentPageIndex)
            }
        }
    }
    
    private func resetZoom() {
        scrollView.zoomScale = scrollView.minimumZoomScale
        DispatchQueue.main.async {
            self.imageView.frame = self.scrollView.bounds
            self.scrollView.contentSize = self.imageView.frame.size
        }
    }
    
    private func updatePageLabel() {
        pageLabel.text = "Page \(currentPageIndex + 1) of \(totalPages)"
    }
    
    private func updateProgress() {
        let progress = totalPages > 0 ? Float(currentPageIndex + 1) / Float(totalPages) : 0
        progressView.setProgress(progress, animated: true)
    }
    
    @objc private func previousPage() {
        guard currentPageIndex > 0 else { return }
        currentPageIndex -= 1
        loadCurrentPage()
        resetHideControlsTimer()
    }
    
    @objc private func nextPage() {
        guard currentPageIndex < totalPages - 1 else { return }
        currentPageIndex += 1
        loadCurrentPage()
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
        let location = gesture.location(in: imageView)
        
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            // Zoom in
            let zoomRect = zoomRectForScale(scrollView.maximumZoomScale / 2, center: location)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            // Zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        
        resetHideControlsTimer()
    }
    
    private func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
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
        
        imageView.frame = contentsFrame
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
            self.loadCurrentPage()
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
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
        resetHideControlsTimer()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerScrollViewContents()
    }
}
