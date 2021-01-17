//
//  TodayPresenter.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/06/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

class TodayPresenter: TodayPresenterProtocol {

    // MARK: - DI

    private let repository: DataRepository
    private let stampsListener: StampsListener
    private let awardsListener: AwardsListener
    private let goalsListener: GoalsListener
    private let calendar: CalendarHelper
    private let awardManager: AwardManager

    private weak var view: TodayView?
    private weak var coordinator: TodayCoordinatorProtocol?

    // Private instance of the data builder
    private let dataBuilder: CalendarDataBuilder

    // MARK: - Lifecycle

    init(
        repository: DataRepository,
        stampsListener: StampsListener,
        awardsListener: AwardsListener,
        goalsListener: GoalsListener,
        awardManager: AwardManager,
        calendar: CalendarHelper,
        view: TodayView,
        coordinator: TodayCoordinatorProtocol
    ) {
        self.repository = repository
        self.stampsListener = stampsListener
        self.awardsListener = awardsListener
        self.goalsListener = goalsListener
        self.awardManager = awardManager
        self.calendar = calendar
        self.view = view
        self.coordinator = coordinator
        
        self.dataBuilder = CalendarDataBuilder(
            repository: repository,
            calendar: calendar
        )
    }

    // MARK: - State

    // All available stamps (to be shown in stamp selector)
    private var allStamps: [Stamp] = []
    
    // Date header data for the week
    private var weekHeader: [DayHeaderData] = []
    
    // Days stickers data for the week
    private var dailyStickers: [[StickerData]] = []

    // Current stamps selected for the day
    private var selectedDayStickers = [Int64]()
    
    // Current awards
    private var awards = [Award]()
    
    // Current goals
    private var goals = [Goal]()
    
    // Current week index
    private var week = CalendarHelper.Week(Date()) {
        didSet {
            // Load data model from the repository
            weekHeader = week.dayHeadersForWeek(highlightedIndex: selectedDayIndex)
            dailyStickers = dataBuilder.weekDataModel(for: week)
            awards = dataBuilder.awards(for: week)
            
            if week.isCurrentWeek {
                goals = repository.allGoals()
            } else {
                goals = []
            }
        }
    }
    
    // Current date
    private var selectedDay = Date() {
        didSet {
            // Calculate distance from today and lock/unlock stamp selector
            let untilToday = Int(selectedDay.timeIntervalSince(Date()) / (60*60*24))
            locked = (untilToday > 0) ?
                // Selected day is in the future
                ((untilToday+1) > Specs.editingForwardDays) :
                // Selected day is in the past
                (untilToday < -Specs.editingBackDays)

            // Update current day stamps from the repository
            selectedDayStickers = repository.stampsIdsForDay(selectedDay)
        }
    }

    // Currently selected day index
    private var selectedDayIndex: Int = -1 {
        didSet {
            weekHeader = week.dayHeadersForWeek(highlightedIndex: selectedDayIndex)
        }
    }
    
    // Lock out dates too far from today
    private var locked: Bool = false {
        didSet {
            let lastSelectorState = selectorState
            selectorState = locked ? .hidden :
                (lastSelectorState == .hidden ? .fullSelector : lastSelectorState)
            
        }
    }
    
    // Stamp selector state
    private var selectorState: SelectorState = .hidden {
        didSet {
            view?.showStampSelector(selectorState)
        }
    }
    
    // To make sure we don't play sound on initial page load (when awards are updated)
    private var firstTime: Bool = true

    /// Called when view finished initial loading.
    func onViewDidLoad() {

        // Configure listeners for the database
        setupListeners()

        // Initial data configuration for the current date
        initializeDataFor(date: Date())
        
        // Configuring view according to the data
        setupView()
    }
    
    func onViewWillAppear() {
        loadViewData()
    }
    
    // MARK: - Private helpers

    /// Reacting to significate time change event - updating data to current date and refreshing view
    @objc func significantTimeChange() {
        print("Significant Time Change")
        
        // Initial data configuration for the current date
        initializeDataFor(date: Date())
        
        // Configuring view according to the data
        setupView()
        loadViewData()
    }

    /// Reacting to significate time change event - updating data to current date and refreshing view
    @objc func weekRecap() {
        print("Navigating to week recap")
        
        // Initial data configuration for the current date
        initializeDataFor(date: Date().byAddingWeek(-1))
        
        // Configuring view according to the data
        setupView()
        loadViewData()
        coordinator?.showAwardsRecap(data: self.recapData())
    }

    /// Initialize data objects based on the current date
    private func initializeDataFor(date: Date) {
        // Load set of all stamps
        allStamps = repository.allStamps()

        // Set date and week objects
        selectedDay = date
        week = CalendarHelper.Week(date)
        
        let key = selectedDay.databaseKey
        selectedDayIndex = weekHeader.firstIndex(where: { $0.date.databaseKey == key }) ?? 0
    }
    
    
    /// Configure listeners to the data source changes
    private func setupListeners() {
        
        // When stamps are updated
        stampsListener.startListening(onError: { error in
            fatalError("Unexpected error: \(error)")
        },
        onChange: { [weak self] stamps in
            guard let self = self else { return }
            
            self.allStamps = self.repository.allStamps()
            self.loadStampSelectorData()
        })
        
        // When awards are updated
        awardsListener.startListening(onChange: { [weak self] in
            guard let self = self else { return }

            let newAwards = self.dataBuilder.awards(for: self.week)
            if newAwards.count > self.awards.count {
                if self.firstTime {
                    self.firstTime = false
                } else {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }
            self.awards = newAwards
            self.loadAwardsData()
        })
        
        // When goals are updated
        goalsListener.startListening(onError: { error in
            fatalError("Unexpected error: \(error)")
        },
        onChange: { [weak self] awards in
            guard let self = self else { return }
            self.goals = self.repository.allGoals()
            self.loadAwardsData()
        })

        // Subscribe to significant time change notification
        NotificationCenter.default.addObserver(self, selector: #selector(significantTimeChange),
            name: UIApplication.significantTimeChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(weekRecap),
            name: .viewWeekRecap, object: nil)
    }

    private func setupView() {
        
        // Subscribe to view callbacks
        view?.onStampInSelectorTapped = { [weak self] stampId in
            self?.stampToggled(stampId: stampId)
        }
        view?.onNewStickerTapped = { [weak self] in
            self?.coordinator?.newSticker()
        }
        view?.onDayHeaderTapped = { [weak self] index in
            self?.selectDay(with: index)
        }
        view?.onNextWeekTapped = { [weak self] in
            self?.advanceWeek(by: 1)
        }
        view?.onPrevWeekTapped = { [weak self] in
            self?.advanceWeek(by: -1)
        }
        view?.onPlusButtonTapped = { [weak self] in
            if self?.locked == false {
                self?.selectorState = .fullSelector
            }
        }
        view?.onCloseStampSelector = { [weak self] in
            self?.selectorState = .miniButton
        }
        view?.onAwardTapped = { [weak self] in
            guard let self = self else { return }
            
            // We should show recap window only for the past weeks
            // Presumably list of goals/awards on the top for the future will be empty,
            // so this callback won't be possible to call for the future weeks
            // Disabling current week should be enough.
            if !self.week.isCurrentWeek {
                self.coordinator?.showAwardsRecap(data: self.recapData())
            }
        }
    }
    
    private func loadViewData() {
        // Title and nav bar
        view?.setTitle(to: week.label)
        view?.showNextPrevButtons(
            showPrev: dataBuilder.canMoveBackward(week),
            showNext: dataBuilder.canMoveForward(week)
        )

        // Awards strip on the top
        loadAwardsData()
        
        // Week header data
        view?.loadWeekHeader(data: weekHeader)

        // Column data
        view?.loadDays(data: dailyStickers)
        
        // Stamp selector data
        loadStampSelectorData()
        
        // Update selectors state based on the lock status
        view?.showStampSelector(selectorState)
    }
    
    private func loadStampSelectorData() {
        var data: [StampSelectorElement] = allStamps.compactMap({
            guard let id = $0.id else { return nil }
            return StampSelectorElement.stamp(
                StickerData(
                    stampId: id,
                    label: $0.label,
                    color: $0.color,
                    isUsed: selectedDayStickers.contains(id)
                )
            )
        })
        
        if data.count < 5 {
            data.append(.newStamp)
        }
        
        view?.loadStampSelector(data: data)
    }
    
    private func recapData() -> [AwardRecapData] {
        return awards.compactMap({
            guard let goal = repository.goalById($0.goalId) else { return nil }

            let stamp = repository.stampById(goal.stamps.first)
            let goalAwardData = GoalAwardData(
                award: $0,
                goal: goal,
                stamp: stamp
            )
            return AwardRecapData(
                title: $0.descriptionText,
                progress: goalAwardData
            )
        })
    }
    
    private func loadAwardsData() {
        var data = [GoalAwardData]()
            
        if week.isCurrentWeek {
            data = goals.compactMap({
                let stamp = repository.stampById($0.stamps.first)
                return GoalAwardData(
                    goal: $0,
                    progress: awardManager.currentProgressFor($0),
                    stamp: stamp
                )
            })
            // Put goals that are already reached in front
            data = data.sorted(by: { return $0 < $1 })
        } else {
            data = awards.compactMap({
                guard $0.reached == true else { return nil }
                guard let goal = repository.goalById($0.goalId) else { return nil }
                let stamp = repository.stampById(goal.stamps.first)
                return GoalAwardData(
                    award: $0,
                    goal: goal,
                    stamp: stamp
                )
            })
        }

        view?.loadAwards(data: data)
        view?.showAwards(data.count > 0)
    }
    
    private func stampToggled(stampId: Int64) {
        guard locked == false else {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            return
        }
        
        if selectedDayStickers.contains(stampId) {
            selectedDayStickers.removeAll { $0 == stampId }
        } else {
            selectedDayStickers.append(stampId)
        }
        
        // Update repository with stamps for today
        repository.setStampsForDay(selectedDay, stamps: selectedDayStickers)
        
        // Recalculate awards
        awardManager.recalculateAwards(selectedDay)
        
        // TODO: Optimize to use listener approach
        if selectedDay.isToday {
            NotificationCenter.default.post(name: .todayStickersUpdated, object: nil)
        }
        
        // Reload the model and update the view
        dailyStickers = dataBuilder.weekDataModel(for: week)
        loadViewData()
    }
    
    // Moving day within selected week
    private func selectDay(with index: Int) {
        selectedDayIndex = index
        selectedDay = weekHeader[index].date

        // Update view
        view?.loadWeekHeader(data: weekHeader)
        loadStampSelectorData()
    }
    
    // Move today's date one week to the past or one week to the future
    private func advanceWeek(by delta: Int) {
        guard delta == 1 || delta == -1 else { return }
        let next = (delta == 1)

        // When navigating week forward - select first day (Monday)
        // When navigating week back - select last day (Sunday)
        let dayDelta = next ? (7 - selectedDayIndex) : (-1 - selectedDayIndex)
        selectedDayIndex = next ? 0 : 6

        selectedDay = selectedDay.byAddingDays(dayDelta)
        week = CalendarHelper.Week(week.firstDay.byAddingWeek(delta))

        // Special logic of we're coming back to the current week
        // Select today's date
        if week.isCurrentWeek {
            selectedDay = Date()
            let key = selectedDay.databaseKey
            selectedDayIndex = weekHeader.firstIndex(where: { $0.date.databaseKey == key }) ?? 0
        }
        
        // Update view
        loadViewData()
    }
}

// MARK: - Specs
fileprivate struct Specs {
    
    /// Editing days back from today (when it's further in the past - entries will become read-only)
    static let editingBackDays = 1

    /// Editing days forward from today (when it's further in the future - entries will become read-only)
    static let editingForwardDays = 2
}
