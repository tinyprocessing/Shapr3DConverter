import Foundation

enum LocalizedString: String {
    case title
    case empty_view_title
    case empty_view_subtitle
    case convert
    case cancel
    case share
}

extension String {
    static func localized(_ string: LocalizedString) -> String {
        return NSLocalizedString(string.rawValue,
                                 tableName: "Localizable",
                                 bundle: .main,
                                 value: string.rawValue,
                                 comment: string.rawValue)
    }
}
