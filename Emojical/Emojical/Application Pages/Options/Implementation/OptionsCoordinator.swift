//
//  OptionsCoordinator.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/29/21.
//  Copyright © 2021 Vladimir Svidersky. All rights reserved.
//

import UIKit

class OptionsCoordinator: OptionsCoordinatorProtocol {
    
    // MARK: - DI

    private weak var parentController: UINavigationController?

    init(
        parent: UINavigationController)
    {
        self.parentController = parent
    }

    /// Navigate to Developer Options
    func developerOptions() {
        // Instantiate DevelopmentViewController from the storyboard file
        guard let dev: DeveloperViewController = Storyboard.Developer.initialViewController() else {
            assertionFailure("Failed to initialize DevelopmentViewController")
            return
        }
        
        // Hook up presenter
        let presenter = DeveloperPresenter(
            view: dev,
            repository: Storage.shared.repository,
            awards: AwardManager.shared,
            settings: LocalSettings.shared
        )
        dev.presenter = presenter
        parentController?.pushViewController(dev, animated: true)
    }
}
