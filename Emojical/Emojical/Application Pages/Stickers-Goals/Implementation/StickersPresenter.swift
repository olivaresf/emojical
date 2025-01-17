//
//  StickersPresenter.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/10/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import Foundation
import UIKit

class StickersPresenter: StickersPresenterProtocol {

    // MARK: - DI

    private let repository: DataRepository
    private let stampsListener: StampsListener
    private let goalsListener: GoalsListener
    private let awardsListener: AwardsListener
    private let awardManager: AwardManager
    
    private weak var view: StickersView?
    private weak var coordinator: StickersCoordinatorProtocol?
    
    // MARK: - State

    // View model data for all stamps
    private var stampsData: [StickerData] = []
    
    // View model data for all goals
    private var goalsData: [GoalData] = []
    
    // MARK: - Lifecycle

    init(
        repository: DataRepository,
        stampsListener: StampsListener,
        goalsListener: GoalsListener,
        awardsListener: AwardsListener,
        awardManager: AwardManager,
        view: StickersView,
        coordinator: StickersCoordinatorProtocol
    ) {
        self.repository = repository
        self.stampsListener = stampsListener
        self.goalsListener = goalsListener
        self.awardsListener = awardsListener
        self.awardManager = awardManager
        self.view = view
        self.coordinator = coordinator
    }

    /// Called when view finished initial loading.
    func onViewDidLoad() {
        setupView()
        
        // Subscribe to stamp listener in case stamps array ever changes
        stampsListener.startListening(onError: { error in
            fatalError("Unexpected error: \(error)")
        },
        onChange: { [weak self] stamps in
            self?.loadViewData()
        })

        // Subscribe to goals listener in case stamps array ever changes
        goalsListener.startListening(onError: { error in
            fatalError("Unexpected error: \(error)")
        },
        onChange: { [weak self] stamps in
            self?.loadViewData()
        })

        // Subscribe to awards listener for when new award is given
        // (to update list of goals including badges)
        awardsListener.startListening(onChange: { [weak self] in
            self?.loadViewData()
        })
    }
    
    /// Called when view about to appear on the screen
    func onViewWillAppear() {
        loadViewData()
    }
    
    // MARK: - Private helpers

    private func setupView() {
        view?.onGoalTapped = { [weak self] goalId in
            guard let goal = self?.repository.goalBy(id: goalId) else { return }
            self?.coordinator?.editGoal(goal)
        }
        view?.onNewGoalTapped = { [weak self] in
            self?.coordinator?.newGoal()
        }
        view?.onStickerTapped = { [weak self] stickerId in
            guard let sticker = self?.repository.stampBy(id: stickerId) else { return }
            self?.coordinator?.editSticker(sticker)
        }
        view?.onNewStickerTapped = { [weak self] in
            self?.coordinator?.newSticker()
        }
        view?.onAddButtonTapped = { [weak self] in
            self?.confirmAddAction()
        }
        view?.onGoalsExamplesTapped = { [weak self] in
            self?.coordinator?.newGoalFromExamples()
        }
    }
    
    private func loadViewData() {
        view?.updateTitle("goals_tab_title".localized)
        let newStampsData = repository.allStamps().sorted(by: { $0.count > $1.count }).map({
            StickerData(
                stampId: $0.id,
                label: $0.label,
                color: $0.color,
                isUsed: false
            )
        })
        
        let newGoalsData: [GoalData] = repository.allGoals().compactMap({
            guard let goalId = $0.id else { return nil }

            let stamp = self.repository.stampBy(id: $0.stamps.first)
            return GoalData(
                goalId: goalId,
                name: $0.name,
                details: Language.goalDescription($0),
                count: $0.count,
                icon: GoalOrAwardIconData(
                    stamp: stamp,
                    goal: $0,
                    progress: self.awardManager.currentProgressFor($0)
                )
            )
        })
        
        var updated = false
        if stampsData != newStampsData {
            stampsData = newStampsData
            updated = true
        }
        if goalsData != newGoalsData {
            goalsData = newGoalsData
            updated = true
        }

        if updated {
            view?.loadData(stickers: stampsData, goals: goalsData)
        }
    }
    
    private func confirmAddAction() {
        let confirm = UIAlertController(
            title: "create_new_title".localized, message: nil, preferredStyle: .actionSheet
        )
        
        confirm.addAction(
            UIAlertAction(title: "sticker_title".localized, style: .default, handler: { (_) in
                self.coordinator?.newSticker()
            })
        )
        confirm.addAction(
            UIAlertAction(title: "goal_title".localized, style: .default, handler: { (_) in
                self.coordinator?.newGoal()
            })
        )
        confirm.addAction(
            UIAlertAction(title: "create_goal_from_examples_title".localized, style: .default, handler: { (_) in
                self.coordinator?.newGoalFromExamples()
            })
        )
        confirm.addAction(
            UIAlertAction(title: "dismiss_button".localized, style: .cancel, handler: { (_) in
                confirm.dismiss(animated: true, completion: nil)
            })
        )
        view?.viewController?.present(confirm, animated: true, completion: nil)
    }
}
