import UIKit

extension UIContentUnavailableConfiguration {
    static func feedLoadingFailed(message: String, retry: @escaping () -> Void) -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "wifi.exclamationmark")
        configuration.text = String(localized: "Не удалось загрузить новости")
        configuration.secondaryText = message
        configuration.button = retryButtonConfiguration()
        configuration.buttonProperties.primaryAction = UIAction { _ in
            retry()
        }
        return configuration
    }

    static func feedEmpty() -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "newspaper")
        configuration.text = String(localized: "Новостей пока нет")
        configuration.secondaryText = String(localized: "Потяните вниз, чтобы обновить")
        return configuration
    }

    static func articleNotSelected() -> UIContentUnavailableConfiguration {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "newspaper")
        configuration.text = String(localized: "Выберите новость")
        configuration.secondaryText = String(localized: "Статья откроется здесь")
        return configuration
    }

    private static func retryButtonConfiguration() -> UIButton.Configuration {
        var button = UIButton.Configuration.filled()
        button.title = String(localized: "Повторить")
        button.baseBackgroundColor = .brand
        button.baseForegroundColor = .onBrand
        button.cornerStyle = .capsule
        return button
    }
}
