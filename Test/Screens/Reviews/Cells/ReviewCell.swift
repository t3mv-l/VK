import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
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
        cell.ratingImageView.image = ratingRenderer.ratingImage(rating)
        cell.updatePhotos(photoURLs: photoURLs)
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
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
        avatarImageView.frame = layout.avatarImageViewFrame
        avatarImageView.layer.cornerRadius = ReviewCellLayout.avatarCornerRadius
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
        photosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for photo in photoURLs {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            
            let activity = UIActivityIndicatorView(style: .medium)
            activity.hidesWhenStopped = true
            imageView.addSubview(activity)
            activity.center = CGPoint(x: 27.5, y: 33)
            
            loadImageWithFallback(photo: photo, imageView: imageView, activity: activity)
            
            photosStackView.addArrangedSubview(imageView)
        }
    }
}

// MARK: - Last (Count) Cell
final class ReviewsCountCell: UITableViewCell {
    let countLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        countLabel.textAlignment = .center
        countLabel.font = UIFont.reviewCount
        countLabel.textColor = UIColor.reviewCount
        contentView.addSubview(countLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        countLabel.frame = contentView.bounds
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
        avatarImageView.image = UIImage(named: "avatar")
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
        photosStackView.spacing = 10
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

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

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
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let contentX = avatarImageViewFrame.maxY + avatarToUsernameSpacing
        let width = maxWidth - contentX - insets.right

        var maxY = insets.top
        var showShowMoreButton = false
        
        avatarImageViewFrame = CGRect(
            origin: CGPoint(x: insets.left, y: insets.top),
            size: Self.avatarSize
        )
                
        let userNameTextHeight = config.userName.boundingRect(width: width).size.height
        userNameLabelFrame = CGRect(
            origin: CGPoint(x: contentX, y: maxY),
            size: CGSize(width: width, height: userNameTextHeight)
        )
        maxY = userNameLabelFrame.maxY + usernameToRatingSpacing
        
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
        maxY = ratingImageViewFrame.maxY + ratingToTextSpacing
        
        let photos = config.photoURLs
        let photosCount = photos.count
        let photoTopSpacing: CGFloat = photosCount > 0 ? ratingToPhotosSpacing : 0
        
        if photosCount > 0 {
            let totalWidth = CGFloat(photosCount) * Self.photoSize.width + CGFloat(photosCount - 1) * photosSpacing
            photosStackViewFrame = CGRect(
                origin: CGPoint(x: contentX, y: maxY + photoTopSpacing),
                size: CGSize(width: totalWidth, height: Self.photoSize.height)
            )
            maxY = photosStackViewFrame.maxY + photosToTextSpacing
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
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: contentX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: contentX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return max(maxY, avatarImageViewFrame.maxY) + insets.bottom + showMoreToCreatedSpacing
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
