import UIKit

final class ReviewsView: UIView {

    let tableView = UITableView()
    let refreshControl = UIRefreshControl()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds.inset(by: safeAreaInsets)
    }

}

// MARK: - Private

private extension ReviewsView {

    func setupView() {
        backgroundColor = .systemBackground
        setupTableView()
        setupRefreshControl()
    }

    func setupTableView() {
        addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCellConfig.reuseId)
    }
    
    func setupRefreshControl() {
        tableView.refreshControl = refreshControl
    }
}

extension ReviewsView {
    // static - чтобы не было ошибки "Extensions must not contain stored properties"
    private static let countLabelHeight: CGFloat = 44
    
    func updateFooter(count: Int) {
        let countLabel = UILabel()
        countLabel.textAlignment = .center
        countLabel.font = UIFont.reviewCount
        countLabel.textColor = UIColor.secondaryLabel
        countLabel.text = "\(count) отзывов"
        countLabel.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: Self.countLabelHeight)
        tableView.tableFooterView = countLabel
    }
}
