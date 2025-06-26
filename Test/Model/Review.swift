/// Модель отзыва.
struct Review: Decodable {
    /// Имя пользователя.
    let first_name: String
    /// Фамилия пользователя.
    let last_name: String
    /// Количество звёзд
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    
    /// Свойство для преобразования значений по ключам "first_name" и "last_name" в одну строку.
    var userName: String {
        return "\(first_name) \(last_name)"
    }
    
}
