//
//  GoalCoordinator.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/18/21.
//  Copyright © 2021 Vladimir Svidersky. All rights reserved.
//

import UIKit

class GoalCoordinator: GoalCoordinatorProtocol {
    
    // MARK: - DI

    private weak var parentController: UINavigationController?

    init(parent: UINavigationController?) {
        self.parentController = parent
    }

    // Navigate to SelectStickers screen
    func selectStickers(_ selectedStickersIds: [Int64], onChange: @escaping ([Int64]) -> Void) {

        guard let stickers = Storyboard.SelectStickers.initialViewController() as? SelectStickersViewController else {
            assertionFailure("Failed to initialize SelectStickersViewController")
            return
        }
        
        stickers.presenter = SelectStickersPresenter(
            view: stickers,
            repository: Storage.shared.repository,
            stampsListener: Storage.shared.stampsListener(),
            coordinator: self,
            selectedStickers: selectedStickersIds
        )
        // Whenever selected stickers changed, notify caller via callback
        stickers.presenter.onChange = { updatedIds in
            onChange(updatedIds)
        }

        parentController?.pushViewController(stickers, animated: true)
    }
    
    func createSticker() {
        // Instantiate StickerViewController from the storyboard file
        guard let nav: UINavigationController = Storyboard.Sticker.initialViewController(),
              let view = nav.viewControllers.first as? StickerViewController else {
            assertionFailure("Failed to initialize StickerViewController")
            return
        }

        let coordinator = StickerCoordinator(parent: nav)
        
        // Hook up GoalPresenter and tie it together to a view controller
        view.presenter = StickerPresenter(
            view: view,
            coordinator: coordinator,
            awardManager: AwardManager.shared,
            repository: Storage.shared.repository,
            sticker: nil,
            presentation: .modal
        )
        parentController?.present(nav, animated: true)
    }
}
