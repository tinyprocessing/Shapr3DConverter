import Foundation

// MARK: - Localized Strings Enum

enum LocalizedString {
    case title
    case empty_view_title
    case empty_view_subtitle
    case convert
    case cancel
    case share
    case convert_to
    case delete
    case kind
    case shapr_document
    case size
    case created
    case modified
    case last_opened
    case unknown

    var key: String {
        switch self {
        default: return String(describing: self)
        }
    }

    enum Placeholder: String {
        case format
    }
}

extension String {
    static func localized(_ key: LocalizedString, _ variables: [LocalizedString.Placeholder: String] = [:]) -> String {
        let localizedString = NSLocalizedString(key.key,
                                                tableName: "Localizable",
                                                bundle: .main,
                                                value: key.key,
                                                comment: key.key)

        return localizedString.replacingPlaceholders(with: variables)
    }
}

// MARK: - String Placeholder Replacing

extension String {
    private func replacingPlaceholders(with variables: [LocalizedString.Placeholder: String]) -> String {
        var result = self
        for (placeholder, value) in variables {
            result = result.replacingOccurrences(of: "{\(placeholder.rawValue)}", with: value)
        }
        return result
    }
}
