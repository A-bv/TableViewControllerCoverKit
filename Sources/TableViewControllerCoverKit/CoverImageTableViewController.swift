import UIKit

/// A `UITableViewController` whose list scrolls over a cover image: the image sits behind the
/// rows with a once-rendered vignette, springs on overscroll, and a navigation bar that fades
/// in as the list rises over it. Subclass it and hand it an image:
///
///     final class MyList: CoverImageTableViewController {
///         override func viewDidLoad() {
///             super.viewDidLoad()
///             setCoverImage(UIImage(named: "cover"))
///         }
///     }
open class CoverImageTableViewController: UITableViewController {

    /// Corner radius where the list meets the image.
    public var coverCornerRadius: CGFloat = 22

    /// Override for the bar area that positions the content below the cover.
    /// Derived from the top safe-area inset when `nil`.
    public var expandedBarHeight: CGFloat?

    /// The bar's background once it has fully faded in.
    public var barBackgroundColor: UIColor = .systemBackground {
        didSet { lastAppliedBarKey = nil }
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
    }

    private var coverImageView = UIImageView()
    private let coverBackgroundView = UIView()
    private static let vignetteContext = CIContext()

    private var sourceImage: UIImage?
    private var installedCoverSize: CGSize = .zero
    private var hasPositionedContent = false
    private var lastAppliedBarKey: CGFloat?
    private var maxSafeAreaTopSeen: CGFloat = 0

    // MARK: - Cover

    /// Installs `image` behind the list and pushes the content below its visible half. Passing
    /// `nil` keeps the current image and just refreshes the layout.
    public func setCoverImage(_ image: UIImage?) {
        if let image { sourceImage = image }
        installedCoverSize = .zero          // force a re-render
        installCoverIfNeeded()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installCoverIfNeeded()
    }

    /// Renders the cover and refreshes the insets, but only when the display size changed — so
    /// the vignette isn't re-run on every layout pass.
    private func installCoverIfNeeded() {
        guard let sourceImage else { return }
        let size = coverDisplaySize
        guard size.width > 0, size.height > 0, size != installedCoverSize else { return }
        installedCoverSize = size

        coverImageView.image = vignetted(resizedToDisplay(sourceImage))
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.frame = CGRect(origin: .zero, size: size)
        if coverImageView.superview == nil { coverBackgroundView.addSubview(coverImageView) }
        tableView.backgroundView = coverBackgroundView
        configureContentInsets()

        // Rest the content below the cover once — the inset is applied after the scroll view
        // sets its initial offset, so it has to be positioned explicitly.
        if !hasPositionedContent {
            hasPositionedContent = true
            tableView.contentOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        }
    }

    private var coverDisplaySize: CGSize {
        CGSize(width: view.bounds.width, height: view.bounds.height / 2 + coverCornerRadius)
    }

    private func configureContentInsets() {
        maxSafeAreaTopSeen = max(maxSafeAreaTopSeen, view.safeAreaInsets.top)
        let barArea = expandedBarHeight.map { $0 + statusBarHeight } ?? maxSafeAreaTopSeen
        let halfHeight = view.bounds.height / 2
        let indicator = halfHeight - (barArea - statusBarHeight) + coverCornerRadius + Constants.scrollIndicatorPadding
        tableView.contentInset = UIEdgeInsets(top: halfHeight - barArea, left: 0, bottom: 0, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: indicator, left: 0, bottom: 0, right: 0)
    }

    /// Status-bar height from this controller's own scene (correct under multi-window).
    private var statusBarHeight: CGFloat {
        let scene = view.window?.windowScene
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        return scene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    // MARK: - Bar fade + spring stretch

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAppliedBarKey = nil          // re-apply: another screen may have changed the bar
        applyBarTransparency()
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let barHeight = navigationController?.navigationBar.frame.height ?? 0
        barFadeProgress = Self.fadeProgress(offset: offset, barHeight: barHeight, statusBarHeight: statusBarHeight)
        applyBarTransparency()

        // Stretch the cover by the overscroll once the list is pulled past its resting top.
        let restOffset = -scrollView.adjustedContentInset.top
        coverImageView.frame.size.height = coverDisplaySize.height + max(0, restOffset - offset)
    }

    /// Negative while the bar floats transparently over the image, 0...1 as the list scrolls up
    /// to meet the bar. Pure, so it's testable directly.
    static func fadeProgress(offset: CGFloat, barHeight: CGFloat, statusBarHeight: CGFloat) -> CGFloat {
        min(1, (offset + barHeight + 2 * statusBarHeight) / Constants.barFadeDistance)
    }

    /// Rebuilds the bar appearance only through the fade — it's constant while transparent
    /// (progress < 0) and while fully opaque (progress == 1).
    private func applyBarTransparency() {
        let key: CGFloat = barFadeProgress < 0 ? -1 : barFadeProgress
        guard key != lastAppliedBarKey else { return }
        lastAppliedBarKey = key

        let overImage = barFadeProgress < 0
        let textColor: UIColor = overImage ? .white : .label.withAlphaComponent(barFadeProgress)
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

    // MARK: - Image rendering

    /// Applies the vignette once into a bitmap (a CIImage-backed image would re-run the filter
    /// every frame as the stretch resizes the view). Returns the input if the filter is missing.
    private func vignetted(_ image: UIImage) -> UIImage {
        guard let input = CIImage(image: image), let filter = CIFilter(name: "CIVignetteEffect") else { return image }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(Constants.vignetteIntensity, forKey: "inputIntensity")
        filter.setValue(Constants.vignetteRadius, forKey: "inputRadius")
        guard let output = filter.outputImage,
              let cg = Self.vignetteContext.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Scales `image` to fill the cover's display size (aspect fill, centre-cropped).
    private func resizedToDisplay(_ image: UIImage) -> UIImage {
        let size = coverDisplaySize
        return UIGraphicsImageRenderer(size: size).image { _ in
            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
    }
}
