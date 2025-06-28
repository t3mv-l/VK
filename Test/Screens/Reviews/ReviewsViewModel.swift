import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State, [Int]?, Bool) -> Void)?

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }
    
    /// Метод обновления отзывов.
    func refreshReviews() {
        state = State()
        state.isRefresh = true
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            let newItems = reviews.items.map(makeReviewItem)
            
            if state.isRefresh {
                // При полном обновлении заменяем все элементы
                state.items = newItems
                state.isRefresh = false
                state.offset = state.limit
                state.shouldLoad = state.offset < reviews.count
                
                // Полная перезагрузка таблицы
                onStateChange?(state, nil, false)
            } else {
                // При обычной загрузке добавляем новые элементы
                let startIndex = state.items.count
                state.items += newItems
                state.offset += state.limit
                state.shouldLoad = state.offset < reviews.count
                
                let newIndexes = (startIndex..<(startIndex + newItems.count)).map { $0 }
                // Добавление новых строк
                onStateChange?(state, newIndexes, true)
            }
        } catch {
            state.shouldLoad = true
            state.isRefresh = false
            onStateChange?(state, nil, false)
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state, [index], false)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let userNameText = review.userName.attributed(font: .username)
        let photoURLs = review.photo_urls ?? []
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let item = ReviewItem(
            userName: userNameText,
            rating: review.rating,
            photoURLs: photoURLs,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    //static - чтобы не было ошибки "Extensions must not contain stored properties"
    private static let countLabelCell: Int = 1

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count + Self.countLabelCell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < state.items.count {
            let config = state.items[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
            config.update(cell: cell, ratingRenderer: ratingRenderer)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewsCountCell", for: indexPath) as! ReviewsCountCell
            cell.countLabel.text = "\(state.items.count) отзывов"
            cell.selectionStyle = .none
            return cell
        }
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    private static let lastCellHeight: CGFloat = 50

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < state.items.count {
            state.items[indexPath.row].height(with: tableView.bounds.size)
        } else {
            Self.lastCellHeight
        }
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
