//
//  SelectStickersPresenter.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/23/21.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class SelectStickersPresenter: SelectStickersPresenterProtocol {

    // MARK: - DI

    private weak var view: SelectStickersView?
    private let repository: DataRepository
    private let stampsListener: StampsListener
    private let coordinator: GoalCoordinatorProtocol

    // MARK: - State
    
    private var selectedStickers: [Int64]
    private var allStickers: [Stamp]

    // MARK: - Lifecycle

    init(
        view: SelectStickersView,
        repository: DataRepository,
        stampsListener: StampsListener,
        coordinator: GoalCoordinatorProtocol,
        selectedStickers: [Int64]
    ) {
        self.view = view
        self.repository = repository
        self.stampsListener = stampsListener
        self.coordinator = coordinator
        self.selectedStickers = selectedStickers
        self.allStickers = [Stamp]()
    }

    // MARK: - SelectStickersPresenterProtocol
    
    /// Selected stickers changed
    var onChange: (([Int64]) -> Void)?

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
    }
    
    func onViewWillAppear() {
        loadViewData()
    }
    
    // MARK: - Private helpers

    private func setupView() {
        view?.onStickerTapped = { [weak self] stickerId in
            self?.toggleSelectedSticker(with: stickerId)
        }
        view?.onNewStickerTapped = { [weak self] in
            self?.coordinator.createSticker()
        }
    }
    
    private func loadViewData() {
        let newStickers = repository.allStamps()

        // If the difference between old and new stickers are only 1 and it was added
        // - it means user tapped on "+" and created new sticker, let's select it
        // automatically
        let diff = newStickers.difference(from: self.allStickers)
        if diff.count == 1 {
            switch diff.first {
            case .insert(_, let stamp, _):
                selectedStickers.append(stamp.id ?? 0)
            default:
                break
            }
        }

        allStickers = newStickers
        var data: [SelectStickerElement] = allStickers.map {
            return SelectStickerElement.sticker(
                SelectStickerData(
                    sticker: $0,
                    selected: selectedStickers.contains($0.id ?? -1)
                )
            )
        }
        
        data.append(.newSticker)
        view?.updateTitle("select_stickers_title".localized)
        view?.loadData(data)
        onChange?(selectedStickers)
    }
    
    private func toggleSelectedSticker(with id: Int64) {
        if selectedStickers.contains(id) {
            selectedStickers.removeAll { $0 == id }
        } else {
            selectedStickers.append(id)
        }
        loadViewData()
    }
}
