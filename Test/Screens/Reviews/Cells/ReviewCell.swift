import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {
    /// Имя пользователя, оставившего отзыв.
    let userName: NSAttributedString
    /// Рейтинг.
    let rating: Int
    /// Изображения (при их наличии).
    let photoURLs: [PhotoURL]
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()
    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    
    var layoutKey: LayoutKey {
        LayoutKey(
            userName: userName.string,
            rating: rating,
            photoURLs: photoURLs,
            reviewText: reviewText.string,
            maxLines: maxLines,
            created: created.string
        )
    }
    
    struct LayoutKey: Hashable {
        let userName: String
        let rating: Int
        let photoURLs: [PhotoURL]
        let reviewText: String
        let maxLines: Int
        let created: String
    }

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell, ratingRenderer: RatingRenderer) {
        guard let cell = cell as? ReviewCell else { return }
        cell.userNameLabel.attributedText = userName
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.ratingImageView.image = cachedRatingImage(for: rating, renderer: ratingRenderer)
        cell.updatePhotos(photoURLs: photoURLs)
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        Layout.heightFor(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate let avatarImageView = UIImageView()
    fileprivate let userNameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let photosStackView = UIStackView()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    
    /// Свойство для сравнения, загружались ли фото по указанным URL ранее
    private var lastPhotoURLs: [String] = []

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        
        _ = layout.calculate(config: config!, maxWidth: bounds.width)
        
        avatarImageView.frame = layout.avatarImageViewFrame
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
        
        userNameLabel.frame = layout.userNameLabelFrame
        ratingImageView.frame = layout.ratingImageViewFrame
        photosStackView.frame = layout.photosStackViewFrame
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        
        photosStackView.isHidden = photosStackView.frame == .zero
    }
    
    func updatePhotos(photoURLs: [PhotoURL]) {
        // закругление изображений
        let imageViewCornerRadius: CGFloat = 8.0
        // половина одного изображения по ширине
        let activityX: CGFloat = 27.5
        // половина одного изображения по высоте
        let activityY: CGFloat = 33.0
        
        let urls = photoURLs.map { $0.google }
        guard urls != lastPhotoURLs else { return }
        lastPhotoURLs = urls
        
        photosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let photoSize = CGSize(width: 55, height: 66)
        for photo in photoURLs {
            let imageView = UIImageView()
            imageView.contentMode = .scaleToFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = imageViewCornerRadius
            
            let activity = UIActivityIndicatorView(style: .medium)
            activity.hidesWhenStopped = true
            imageView.addSubview(activity)
            activity.center = CGPoint(x: activityX, y: activityY)
            
            loadImageWithFallback(photo: photo, imageView: imageView, activity: activity, targetSize: photoSize)
            
            photosStackView.addArrangedSubview(imageView)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        lastPhotoURLs = []
        photosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupAvatarImageView()
        setupUserNameTextLabel()
        setupRatingImageView()
        setupPhotosStackView()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
    }
    
    func setupAvatarImageView() {
        contentView.addSubview(avatarImageView)
        loadAvatar(named: "avatar", into: avatarImageView)
    }
    
    func setupUserNameTextLabel() {
        contentView.addSubview(userNameLabel)
    }
    
    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
    }
    
    func setupPhotosStackView() {
        contentView.addSubview(photosStackView)
        photosStackView.axis = .horizontal
        photosStackView.distribution = .fillEqually
        photosStackView.spacing = Layout.spacingBetweenPhotos
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }

    private func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(self, action: #selector(showMoreTapped), for: .touchUpInside)
    }
    
    @objc private func showMoreTapped() {
        config?.onTapShowMore(config?.id ?? UUID())
    }
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {
    
    private static var heightCache = [CacheKey: CGFloat]()
    private struct CacheKey: Hashable {
        let layoutKey: Config.LayoutKey
        let maxWidth: CGFloat
    }

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0
    fileprivate static let spacingBetweenPhotos: CGFloat = 10.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы
    
    private(set) var avatarImageViewFrame = CGRect.zero
    private(set) var userNameLabelFrame = CGRect.zero
    private(set) var ratingImageViewFrame = CGRect.zero
    private(set) var photosStackViewFrame = CGRect.zero
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private static let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    /// Горизонтальный отступ от аватара до имени пользователя.
    private static let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private static let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private static let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private static let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private static let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private static let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private static let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private static let showMoreToCreatedSpacing = 6.0
    
    // MARK: - Расчёт фреймов и высоты ячейки
    
    /// Возвращает высоту ячейки с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    static func heightFor(config: Config, maxWidth: CGFloat) -> CGFloat {
        let key = CacheKey(layoutKey: config.layoutKey, maxWidth: maxWidth)
        if let cached = heightCache[key] {
            return cached
        }
        
        let contentX = insets.left + self.avatarSize.width + avatarToUsernameSpacing
        let width = maxWidth - contentX - insets.right
        
        var maxY = insets.top
        
        maxY += config.userName.boundingRect(width: width).size.height
        maxY += usernameToRatingSpacing
        
        let ratingConfig = RatingRendererConfig.default()
        maxY += ratingConfig.starImage.size.height
        
        let photosCount = config.photoURLs.count
        if photosCount > 0 {
            maxY += ratingToPhotosSpacing
            maxY += self.photoSize.height
            maxY += photosToTextSpacing
        } else {
            maxY += ratingToTextSpacing
        }
        
        var showShowMoreButton = false
        if !config.reviewText.isEmpty() {
            let fontLineHeight = config.reviewText.font()?.lineHeight ?? .zero
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            let currentTextHeight = fontLineHeight * CGFloat(config.maxLines)
            
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
            
            let heightToDraw = showShowMoreButton ? currentTextHeight : actualTextHeight
            maxY += config.reviewText.boundingRect(width: width, height: heightToDraw).size.height
            maxY += reviewTextToCreatedSpacing
        }
        
        if showShowMoreButton {
            maxY += Self.showMoreButtonSize.height
            maxY += showMoreToCreatedSpacing
        }
        
        maxY += config.created.boundingRect(width: width).size.height
        
        let finalHeight = max(maxY, avatarSize.height + insets.top) + insets.bottom + showMoreToCreatedSpacing
        
        heightCache[key] = finalHeight
        
        return finalHeight
    }
    
    func calculate(config: Config, maxWidth: CGFloat) -> CGFloat {
        let contentX = Self.insets.left + Self.avatarSize.width + Self.avatarToUsernameSpacing
        let width = maxWidth - contentX - Self.insets.right
        
        var maxY = Self.insets.top
        var showShowMoreButton = false
        
        avatarImageViewFrame = CGRect(
            origin: CGPoint(x: Self.insets.left, y: Self.insets.top),
            size: Self.avatarSize
        )
        
        let userNameTextHeight = config.userName.boundingRect(width: width).size.height
        userNameLabelFrame = CGRect(
            origin: CGPoint(x: contentX, y: maxY),
            size: CGSize(width: width, height: userNameTextHeight)
        )
        maxY = userNameLabelFrame.maxY + Self.usernameToRatingSpacing
        
        let ratingConfig = RatingRendererConfig.default()
        // Ширина - это ширина одной звезды и отступ, умноженные на количество звёзд и минус последний отступ
        let ratingImageSize = CGSize(
            width: (ratingConfig.starImage.size.width + ratingConfig.spacing) * CGFloat(ratingConfig.ratingRange.upperBound) - ratingConfig.spacing,
            height: ratingConfig.starImage.size.height
        )
        ratingImageViewFrame = CGRect(
            origin: CGPoint(x: contentX, y: maxY),
            size: ratingImageSize
        )
        maxY = ratingImageViewFrame.maxY + Self.ratingToTextSpacing
        
        let photos = config.photoURLs
        let photosCount = photos.count
        let photoTopSpacing: CGFloat = photosCount > 0 ? Self.ratingToPhotosSpacing : 0
        
        if photosCount > 0 {
            let totalWidth = CGFloat(photosCount) * Self.photoSize.width + CGFloat(photosCount - 1) * Self.photosSpacing
            photosStackViewFrame = CGRect(
                origin: CGPoint(x: contentX, y: maxY + photoTopSpacing),
                size: CGSize(width: totalWidth, height: Self.photoSize.height)
            )
            maxY = photosStackViewFrame.maxY + Self.photosToTextSpacing
        } else {
            photosStackViewFrame = .zero
        }
        
        if !config.reviewText.isEmpty() {
            let fontLineHeight = config.reviewText.font()?.lineHeight ?? .zero
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
        
            let currentTextHeight: CGFloat
            if config.maxLines == 0 {
                // Максимально возможная высота текста, если бы ограничения не было.
                currentTextHeight = actualTextHeight
            } else {
                // Высота текста с текущим ограничением по количеству строк.
                currentTextHeight = fontLineHeight * CGFloat(config.maxLines)
            }
        
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
        
            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: contentX, y: maxY),
                size: config.reviewText.boundingRect(width: width, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + Self.reviewTextToCreatedSpacing
        }
        
        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: contentX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + Self.showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }
        
        createdLabelFrame = CGRect(
            origin: CGPoint(x: contentX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )
        
        return max(maxY, avatarImageViewFrame.maxY) + Self.insets.bottom + Self.showMoreToCreatedSpacing
    }
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
