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

    /// Estimated expanded-bar height used to position the content's top edge.
    public var expandedBarHeight: CGFloat = 96

    /// The bar's background color once it has fully faded in.
    public var barBackgroundColor: UIColor = .systemBackground

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
    }

    private var coverImageView = UIImageView()
    private static let vignetteContext = CIContext()

    // MARK: - Cover image

    /// Installs `image` behind the list — rendered at display size with the vignette
    /// applied once — and pushes the content below the image's visible half. Passing nil
    /// keeps the previous image and only refreshes the layout.
    public func setCoverImage(_ image: UIImage?) {
        if let image {
            coverImageView = UIImageView(image: resizedToDisplay(image))
        }
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.frame = CGRect(origin: .zero, size: coverDisplaySize)

        let backgroundView = UIView()
        backgroundView.addSubview(coverImageView)
        tableView.backgroundView = backgroundView

        applyVignette()
        configureContentInsets()
    }

    private var coverDisplaySize: CGSize {
        CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height / 2 + coverCornerRadius)
    }

    private func configureContentInsets() {
        let halfScreen = UIScreen.main.bounds.height / 2
        let topInset = halfScreen - (expandedBarHeight + statusBarHeight)
        let indicatorInset = (halfScreen - expandedBarHeight)
            + coverCornerRadius + Constants.scrollIndicatorPadding

        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: indicatorInset, left: 0, bottom: 0, right: 0)
    }

    private var statusBarHeight: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    // MARK: - Scroll: bar fade + spring stretch

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBarTransparency()
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y

        let barHeight = navigationController?.navigationBar.frame.height ?? 0
        let fadeStart = barHeight + 2 * statusBarHeight
        barFadeProgress = min(1, (offset + fadeStart) / Constants.barFadeDistance)
        applyBarTransparency()

        let bounceThreshold = -UIScreen.main.bounds.height / 2
        if offset < bounceThreshold {
            coverImageView.frame.size.height = -offset + coverCornerRadius
        }
    }

    private func applyBarTransparency() {
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

    /// Rendered once into a bitmap; a CIImage-backed image would re-run the filter on
    /// every draw while the stretch resizes the view per frame.
    private func applyVignette() {
        guard
            let img = coverImageView.image,
            let beginImage = CIImage(image: img),
            let filter = CIFilter(name: "CIVignetteEffect")
        else { return }

        filter.setValue(beginImage, forKey: kCIInputImageKey)
        filter.setValue(Constants.vignetteIntensity, forKey: "inputIntensity")
        filter.setValue(Constants.vignetteRadius, forKey: "inputRadius")

        guard
            let output = filter.outputImage,
            let rendered = Self.vignetteContext.createCGImage(output, from: beginImage.extent)
        else { return }

        coverImageView.image = UIImage(cgImage: rendered, scale: img.scale, orientation: img.imageOrientation)
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
