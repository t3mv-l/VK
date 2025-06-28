import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        reviewsView.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsView] state, changedIndexes, isInsert in
            guard let reviewsView = reviewsView else { return }
            
            reviewsView.refreshControl.endRefreshing()
            
            if let changed = changedIndexes {
                if isInsert {
                    reviewsView.tableView.insertRows(at: changed.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                } else {
                    reviewsView.tableView.reloadRows(at: changed.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                }
            } else {
                reviewsView.tableView.reloadData()
            }
        }
    }
    
    @objc private func refreshData() {
        viewModel.refreshReviews()
    }
}
