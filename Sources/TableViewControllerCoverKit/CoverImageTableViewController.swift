import UIKit

open class CoverImageTableViewController: UITableViewController {

    /// Overrides the resting top inset the cover leaves for the navigation bar. When `nil` (the
    /// default) the inset is derived from the safe-area top.
    public var expandedBarHeight: CGFloat?

    /// Colour the navigation bar fades to as the list scrolls up past the cover image. Defaults to
    /// `.systemBackground`.
    public var barBackgroundColor: UIColor = .systemBackground {
        didSet { lastAppliedBarKey = nil }
    }

    /// When `true`, forces the default status bar style instead of `coverStatusBarStyle` while the
    /// list rests over the cover. Defaults to `false`.
    public var suspendsCoverStatusBarStyle = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    /// Status bar style used while the list rests over the cover image. Defaults to
    /// `.lightContent` for dark covers; set `.darkContent` for light covers. Also drives the
    /// navigation bar's foreground (title and tint) colour over the image.
    public var coverStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            lastAppliedBarKey = nil
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var barFadeProgress: CGFloat = -1 {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if suspendsCoverStatusBarStyle { return .default }
        return barFadeProgress < 0 ? coverStatusBarStyle : .default
    }

    private enum Constants {
        static let scrollIndicatorPadding: CGFloat = 20
        static let vignetteIntensity = 0.12
        static let vignetteRadius = 0.2
        static let barFadeDistance: CGFloat = 50
        static let coverOverlap: CGFloat = 22
    }

    private var coverImageView = UIImageView()
    private let coverBackgroundView = UIView()
    private nonisolated static let vignetteContext = CIContext()

    private var sourceImage: UIImage?
    private var installedCoverSize: CGSize = .zero
    private var hasPositionedContent = false
    private var lastAppliedBarKey: CGFloat?
    private var maxSafeAreaTopSeen: CGFloat = 0
    private var savedBarTintColor: UIColor?

    /// Sets (or replaces) the cover image. The resize and vignette run off the main thread, so the
    /// rendered image is assigned once ready and may appear a frame after this call returns.
    public func setCoverImage(_ image: UIImage) {
        // A zero-dimension image (failed decode, empty asset) would divide by zero in the display
        // resize and render blank. Reject it and keep any cover already set.
        guard image.size.width > 0, image.size.height > 0 else { return }
        sourceImage = image
        installedCoverSize = .zero
        installCoverIfNeeded()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installCoverIfNeeded()
        // Install is gated on cover *size*, which doesn't change when only the safe area does
        // (e.g. the status bar resolving once the view enters a window). Recompute the insets on
        // every pass so they stay correct in that case — it's cheap arithmetic.
        if installedCoverSize != .zero { configureContentInsets() }
    }

    private func installCoverIfNeeded() {
        guard let sourceImage else { return }
        let size = coverDisplaySize
        guard size.width > 0, size.height > 0, size != installedCoverSize else { return }
        installedCoverSize = size

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.frame = CGRect(origin: .zero, size: size)
        if coverImageView.superview == nil { coverBackgroundView.addSubview(coverImageView) }
        tableView.backgroundView = coverBackgroundView
        configureContentInsets()

        if !hasPositionedContent {
            hasPositionedContent = true
            tableView.contentOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        }

        renderCover(sourceImage, at: size)
    }

    /// Renders the cover synchronously instead of off the main thread. Off by default; tests flip it
    /// on so assertions don't race a wall-clock timeout (which is flaky on slow/contended CI runners).
    var rendersCoverSynchronously = false

    /// Resizing plus the Core Image vignette are the expensive part, so they run off the main
    /// thread. The `installedCoverSize` re-check drops any render that a newer size (e.g. a fast
    /// rotation) has already superseded.
    private func renderCover(_ image: UIImage, at size: CGSize) {
        let render: @Sendable () -> UIImage = { Self.vignetted(Self.resizedToDisplay(image, to: size)) }
        let apply: @MainActor (UIImage) -> Void = { [weak self] rendered in
            guard let self, self.installedCoverSize == size else { return }
            self.coverImageView.image = rendered
        }
        guard !rendersCoverSynchronously else { return apply(render()) }
        DispatchQueue.global(qos: .userInitiated).async {
            let rendered = render()
            Task { @MainActor in apply(rendered) }
        }
    }

    private var coverDisplaySize: CGSize {
        CGSize(width: view.bounds.width, height: view.bounds.height / 2 + Constants.coverOverlap)
    }

    private func configureContentInsets() {
        // Ratchets upward on purpose: the safe-area top can momentarily collapse (e.g. the bar
        // hiding mid-transition) and we don't want the cover or content to jump when it does.
        maxSafeAreaTopSeen = max(maxSafeAreaTopSeen, view.safeAreaInsets.top)
        let barArea = expandedBarHeight.map { $0 + statusBarHeight } ?? maxSafeAreaTopSeen
        let halfHeight = view.bounds.height / 2
        let indicator = halfHeight - (barArea - statusBarHeight) + Constants.coverOverlap + Constants.scrollIndicatorPadding
        // Clamp to 0: a large `expandedBarHeight` (or a very short view) can drive these negative,
        // which would pull the first rows up underneath the cover.
        tableView.contentInset = UIEdgeInsets(top: max(0, halfHeight - barArea), left: 0, bottom: 0, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: max(0, indicator), left: 0, bottom: 0, right: 0)
    }

    // Resolved from the view's own window scene only — deliberately avoids `UIApplication.shared`
    // so the library stays compilable in app-extension targets. Reads 0 before the view is in a
    // window, which is fine: the cover is laid out again once it is.
    private var statusBarHeight: CGFloat {
        view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        savedBarTintColor = navigationController?.navigationBar.tintColor
        lastAppliedBarKey = nil
        applyBarTransparency()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // `applyBarTransparency` mutates the *shared* navigation bar's tintColor, so restore it on
        // the way out — otherwise the cover's colour bleeds into whatever is shown next.
        navigationController?.navigationBar.tintColor = savedBarTintColor
    }

    /// Drives the bar fade and the cover's overscroll stretch. If you override this (or any of the
    /// other overridden lifecycle methods), call `super` or those effects stop working.
    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let barHeight = navigationController?.navigationBar.frame.height ?? 0
        barFadeProgress = Self.fadeProgress(offset: offset, barHeight: barHeight, statusBarHeight: statusBarHeight)
        applyBarTransparency()

        let restOffset = -scrollView.adjustedContentInset.top
        coverImageView.frame.size.height = coverDisplaySize.height + max(0, restOffset - offset)
    }

    static func fadeProgress(offset: CGFloat, barHeight: CGFloat, statusBarHeight: CGFloat) -> CGFloat {
        min(1, (offset + barHeight + 2 * statusBarHeight) / Constants.barFadeDistance)
    }

    private func applyBarTransparency() {
        let key: CGFloat = barFadeProgress < 0 ? -1 : barFadeProgress
        guard key != lastAppliedBarKey else { return }
        lastAppliedBarKey = key

        let overImage = barFadeProgress < 0
        let coverForeground: UIColor = coverStatusBarStyle == .lightContent ? .white : .black
        let textColor: UIColor = overImage ? coverForeground : .label.withAlphaComponent(barFadeProgress)
        let background: UIColor = overImage ? .clear : barBackgroundColor.withAlphaComponent(barFadeProgress)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = textColor
    }

    private nonisolated static func vignetted(_ image: UIImage) -> UIImage {
        guard let input = CIImage(image: image), let filter = CIFilter(name: "CIVignetteEffect") else { return image }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(Constants.vignetteIntensity, forKey: "inputIntensity")
        filter.setValue(Constants.vignetteRadius, forKey: "inputRadius")
        guard let output = filter.outputImage,
              let cg = vignetteContext.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }

    private nonisolated static func resizedToDisplay(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
    }
}
