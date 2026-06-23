import UIKit

/// A `UITableViewController` whose content scrolls over a cover image: the image sits
/// behind the list with a once-rendered vignette, stretches with a spring effect on
/// overscroll, and the list content starts below the image's visible half.
///
/// Subclass it and hand it an image — that is the whole API:
///
///     final class MyList: CoverImageTableViewController {
///         override func viewDidLoad() {
///             super.viewDidLoad()
///             setCoverImage(UIImage(named: "cover"))
///         }
///     }
///
/// The class owns the full customization: the navigation bar fades in as the list scrolls
/// over the image, and the status bar reads light while the bar floats over the cover.
open class CoverImageTableViewController: UITableViewController {

    /// Corner radius where the list content meets the image.
    public var coverCornerRadius: CGFloat = 22

    /// The bar height assumed when positioning the content's top edge below the cover. A fixed
    /// estimate on purpose: the live bar height swings while a large title collapses, so a stable
    /// value is needed or the content would shift during the scroll. Adjust it if the gap between
    /// the cover and the first row doesn't suit your bar.
    public var expandedBarHeight: CGFloat = 96

    /// The bar's background color once it has fully faded in.
    public var barBackgroundColor: UIColor = .systemBackground {
        didSet { lastAppliedBarKey = nil }   // force the appearance to rebuild with the new color
    }

    /// Set while a modal covers this screen so the status bar reads normally.
    public var suspendsCoverStatusBarStyle = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    /// Negative while the bar floats over the image, 0...1 while fading in.
    private var barFadeProgress: CGFloat = 0 {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if suspendsCoverStatusBarStyle { return .default }
        return barFadeProgress < 0 ? .lightContent : .default
    }

    private enum Constants {
        static let scrollIndicatorPadding: CGFloat = 20
        static let vignetteIntensity = 0.12
        static let vignetteRadius = 0.2
        static let barFadeDistance: CGFloat = 50
        static let largeTitleFontSize: CGFloat = 31
        /// Roughly the height the large-title row adds to the bar; the scroll distance over
        /// which a large title collapses into the inline title.
        static let largeTitleCollapseDistance: CGFloat = 52
    }

    private var coverImageView = UIImageView()
    private var coverBackgroundView = UIView()
    private static let vignetteContext = CIContext()

    /// The source image, kept so the cover can be re-rendered when the view's size changes
    /// (rotation, iPad multitasking, non-fullscreen scenes) without the caller re-supplying it.
    private var sourceImage: UIImage?

    /// The display size the cover was last rendered at; guards against re-running the vignette
    /// on every layout pass when nothing has changed.
    private var installedCoverSize: CGSize = .zero

    /// Whether the content has been rested below the cover yet (done once, on first install).
    private var hasPositionedContent = false

    /// The last fade state pushed to the navigation bar, so the appearance is only rebuilt
    /// while it actually changes (the brief fade) — not on every scroll callback.
    private var lastAppliedBarKey: CGFloat?

    /// The navigation bar's collapsed height, used to anchor the fade. Large titles make
    /// `navigationBar.frame.height` swing (≈96 expanded → its standard height once collapsed),
    /// so reading it live drifts the fade trigger and the bar darkens late and abruptly. The
    /// smallest height seen is the collapsed one, and it settles before the fade range begins.
    private var collapsedBarHeight: CGFloat = .greatestFiniteMagnitude

    /// The largest navigation-bar height seen — i.e. the expanded large-title height. Used to
    /// measure how far a large title has collapsed.
    private var maxBarHeightSeen: CGFloat = 0

    // MARK: - Cover image

    /// Installs `image` behind the list — rendered at display size with the vignette applied
    /// once — and pushes the content below the image's visible half. Passing nil keeps the
    /// previous image and only refreshes the layout. The cover is sized off the actual view
    /// bounds and re-renders itself when those change, so it survives rotation and resizing.
    public func setCoverImage(_ image: UIImage?) {
        if let image { sourceImage = image }
        installedCoverSize = .zero          // force a re-render for the new image / refresh
        installCoverIfNeeded()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installCoverIfNeeded()
    }

    /// Renders the cover at the current display size and refreshes the insets, but only when
    /// that size actually changed — so rotation and resize are handled without re-running the
    /// vignette on every layout pass.
    private func installCoverIfNeeded() {
        guard sourceImage != nil else { return }     // nothing to install until given an image
        let size = coverDisplaySize
        guard size.width > 0, size.height > 0, size != installedCoverSize else { return }

        installedCoverSize = size

        if let sourceImage {
            coverImageView.image = vignetted(resizedToDisplay(sourceImage))
        }
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.frame = CGRect(origin: .zero, size: size)

        if coverImageView.superview == nil { coverBackgroundView.addSubview(coverImageView) }
        tableView.backgroundView = coverBackgroundView
        configureContentInsets()

        // Rest the content below the cover on first layout. (The inset is applied after the scroll
        // view initialised its offset, so it has to be positioned explicitly; resizes are handled
        // in viewWillTransition, which can capture the position before the bounds change.)
        if !hasPositionedContent {
            hasPositionedContent = true
            tableView.contentOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Preserve how far the list is scrolled across a rotation/resize: capture it now, while
        // the current layout is valid, and restore it once the new layout has settled.
        let scrolledPastRest = tableView.contentOffset.y + tableView.adjustedContentInset.top
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.tableView.adjustedContentInset.top + scrolledPastRest)
        }
    }

    private var coverDisplaySize: CGSize {
        CGSize(width: view.bounds.width, height: view.bounds.height / 2 + coverCornerRadius)
    }

    private func configureContentInsets() {
        let halfHeight = view.bounds.height / 2
        let topInset = halfHeight - (expandedBarHeight + statusBarHeight)
        let indicatorInset = (halfHeight - expandedBarHeight)
            + coverCornerRadius + Constants.scrollIndicatorPadding

        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: indicatorInset, left: 0, bottom: 0, right: 0)
    }

    private var statusBarHeight: CGFloat {
        // This controller's own scene — not a global key-window search — so the height stays
        // correct in multi-window setups (iPad Split View, Stage Manager). Falls back to the
        // foreground-active scene before the view is in a window.
        let scene = view.window?.windowScene
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        return scene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    // MARK: - Scroll: bar fade + spring stretch

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAppliedBarKey = nil          // re-apply on return; another screen may have reset the bar
        applyBarTransparency()
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y

        let barHeight = navigationController?.navigationBar.frame.height ?? 0
        if barHeight > 0 {
            collapsedBarHeight = min(collapsedBarHeight, barHeight)
            maxBarHeightSeen = max(maxBarHeightSeen, barHeight)
        }

        if navigationController?.navigationBar.prefersLargeTitles == true {
            // Large titles: the content offset stays pinned to the top while the bar collapses
            // (the inset shrinks in step with it), so offset can't drive the fade. Track the
            // collapse from the bar height instead and fade in lockstep with it, the way the
            // system fades its own material — the background arrives as the title docks.
            let collapse = min(1, max(0, (maxBarHeightSeen - barHeight) / Constants.largeTitleCollapseDistance))
            barFadeProgress = collapse * 2 - 1
        } else {
            // Standard title: fade as the list scrolls up to meet the bar.
            let stableBarHeight = collapsedBarHeight == .greatestFiniteMagnitude ? barHeight : collapsedBarHeight
            let fadeStart = stableBarHeight + 2 * statusBarHeight
            barFadeProgress = min(1, (offset + fadeStart) / Constants.barFadeDistance)
        }
        applyBarTransparency()

        // Stretch the cover only while the list is pulled past its resting top, by exactly
        // the overscroll amount. Anchoring to the live rest offset (not a fixed half-screen)
        // keeps the cover at its display height at rest — large titles enlarge the top inset,
        // which previously left the cover stretched at rest and shrinking on the first scroll —
        // and starts the spring immediately on pull-down instead of after a dead zone.
        let restOffset = -scrollView.adjustedContentInset.top
        let overscroll = max(0, restOffset - offset)
        coverImageView.frame.size.height = coverDisplaySize.height + overscroll
    }

    private func applyBarTransparency() {
        // The appearance is constant while the bar floats over the image (progress < 0) and
        // while it is fully opaque (progress == 1); only rebuild it through the fade between.
        let key: CGFloat = barFadeProgress < 0 ? -1 : barFadeProgress
        if key == lastAppliedBarKey { return }
        lastAppliedBarKey = key

        let overImage = barFadeProgress < 0
        let textColor: UIColor = overImage ? .white : .label.withAlphaComponent(barFadeProgress)
        let backgroundColor: UIColor = overImage ? .clear : barBackgroundColor.withAlphaComponent(barFadeProgress)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: Constants.largeTitleFontSize, weight: .bold),
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = textColor
    }

    // MARK: - Vignette

    /// Baked into a bitmap once per size; a CIImage-backed image would re-run the filter on
    /// every draw while the stretch resizes the view per frame. Returns the input unchanged
    /// if the filter is unavailable.
    private func vignetted(_ image: UIImage) -> UIImage {
        guard
            let beginImage = CIImage(image: image),
            let filter = CIFilter(name: "CIVignetteEffect")
        else { return image }

        filter.setValue(beginImage, forKey: kCIInputImageKey)
        filter.setValue(Constants.vignetteIntensity, forKey: "inputIntensity")
        filter.setValue(Constants.vignetteRadius, forKey: "inputRadius")

        guard
            let output = filter.outputImage,
            let rendered = Self.vignetteContext.createCGImage(output, from: beginImage.extent)
        else { return image }

        return UIImage(cgImage: rendered, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Resize

    private func resizedToDisplay(_ image: UIImage) -> UIImage {
        let newSize = coverDisplaySize
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / image.size.height
            let vScale = newSize.width / image.size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width - newSize.width) / 2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height - newSize.height) / 2.0
            }
            image.draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}
