import UIKit

final class RootView: UIView {
    
    private let backgroundView = UIImageView()
    private let reviewsButton = UIButton(type: .system)
    private let onTapReviews: () -> Void
    
    private let spacingX: CGFloat = 7
    private let spacingY: CGFloat = 10
    private let labelFontSize: CGFloat = 24

    init(onTapReviews: @escaping () -> Void) {
        self.onTapReviews = onTapReviews
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Private

private extension RootView {

    func setupView() {
        backgroundColor = .systemBackground
        backgroundView.image = UIImage(named: "rootViewBackground")
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundView, at: 0)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        setupReviewsButton()
    }

    func setupReviewsButton() {
        reviewsButton.setTitle("Отзывы", for: .normal)
        reviewsButton.titleLabel?.font = .systemFont(ofSize: labelFontSize, weight: .semibold)
        reviewsButton.addAction(UIAction { [unowned self] _ in onTapReviews() }, for: .touchUpInside)
        reviewsButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reviewsButton)
        NSLayoutConstraint.activate([
            reviewsButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: spacingX),
            reviewsButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: spacingY)
        ])
    }

}
