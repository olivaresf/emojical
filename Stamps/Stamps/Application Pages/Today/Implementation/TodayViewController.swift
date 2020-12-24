//
//  TodayViewController.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/06/2020.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit
import AudioToolbox

class TodayViewController: UIViewController, TodayView {

    // MARK: - Outlets

    /// List of awards / goals on the top of the view
    @IBOutlet weak var awards: WeeklyAwardsView!

    /// Constraint to hide awards list if there are no goals defined
    @IBOutlet weak var separatorTopConstraint: NSLayoutConstraint!

    /// Days header view
    @IBOutlet weak var daysHeader: DaysHeaderView!

    /// Selected day indicator above day header view
    @IBOutlet weak var selectedDayIndicator: UIView!
    @IBOutlet weak var selectedDayIndicatorLeading: NSLayoutConstraint!

    @IBOutlet var prevWeek: UIBarButtonItem!
    @IBOutlet var nextWeek: UIBarButtonItem!

    @IBOutlet weak var day0: DayColumnView!
    @IBOutlet weak var day1: DayColumnView!
    @IBOutlet weak var day2: DayColumnView!
    @IBOutlet weak var day3: DayColumnView!
    @IBOutlet weak var day4: DayColumnView!
    @IBOutlet weak var day5: DayColumnView!
    @IBOutlet weak var day6: DayColumnView!
    
    @IBOutlet weak var stampSelector: StampSelectorView!
    @IBOutlet weak var stampSelectorBottomContstraint: NSLayoutConstraint!

    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var plusButtonBottomContstraint: NSLayoutConstraint!


    // MARK: - DI

    var presenter: TodayPresenterProtocol!

    // Reference arrays for easier access
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = TodayPresenter(
            repository: Storage.shared.repository,
            stampsListener: Storage.shared.stampsListener(),
            awardsListener: Storage.shared.awardsListener(),
            goalsListener: Storage.shared.goalsListener(),
            awardManager: AwardManager.shared,
            calendar: CalendarHelper.shared,
            view: self,
            coordinator: self)
        
        configureViews()
        presenter.onViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.onViewWillAppear()
    }
    
    // MARK: - TodayView
    
    /// Is called when user tapped on the stamp in the bottom stamp selector
    var onStampInSelectorTapped: ((Int64) -> Void)?

    /// User tapped on create new stamp in the bottom stamp selector
    var onNewStickerTapped: (() -> Void)?

    /// Is called when user tapped on the day header, day index 0...6 is passed
    var onDayHeaderTapped: ((Int) -> Void)?

    /// User tapped on the previous week button
    var onPrevWeekTapped: (() -> Void)?

    /// User tapped on the next week button
    var onNextWeekTapped: (() -> Void)? 

    /// User tapped on the plus button
    var onPlusButtonTapped: (() -> Void)?

    /// User tapped to close selector button
    var onCloseStampSelectorTapped: (() -> Void)?

    /// Show/hide top awards strip
    func showAwards(_ show: Bool) {
        separatorTopConstraint.constant = show ? 70 : -1
    }

    /// Update page title
    func setTitle(to title: String) {
        navigationItem.title = title
    }

    /// Move selected day indicator
    func setSelectedDay(to index: Int) {
        DispatchQueue.main.async {
            let size = self.day0.bounds.width
            self.selectedDayIndicatorLeading.constant = CGFloat(index) * size + size / 2
        }
    }

    /// Loads stamps and header data into day columns
    func loadDaysData(header: [DayHeaderData], daysData: [[StickerData]]) {
        guard daysData.count == 7,
              header.count == 7 else { return }
        
        let dayViews: [DayColumnView] = [day0, day1, day2, day3, day4, day5, day6]
        
        // Mapping 7 data objects to 7 day views
        for (day, view) in zip(daysData, dayViews) {
            view.loadData(data: day)
        }
        
        daysHeader.loadData(data: header)
    }

    /// Loads awards data
    func loadAwardsData(data: [GoalAwardData]) {
        awards.loadData(data: data)
    }

    /// Loads stamps into stamp selector
    func loadStampSelectorData(data: [StampSelectorElement]) {
        stampSelector.loadData(data: data)
    }
    
    /// Show/hide next/prev button
    func showNextPrevButtons(showPrev: Bool, showNext: Bool) {
        navigationItem.leftBarButtonItem = showPrev ? prevWeek : nil
        navigationItem.rightBarButtonItem = showNext ? nextWeek : nil
    }

    /// Show/hide stamp selector and plus button
    func showStampSelector(_ state: SelectorState) {
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0,
            options: [.curveEaseInOut], animations:
        {
            self.adjustButtonConstraintsForState(state)
        })
    }

    // MARK: - Actions
    
    @IBAction func prevButtonTapped(_ sender: Any) {
        onPrevWeekTapped?()
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        onNextWeekTapped?()
    }
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        onPlusButtonTapped?()
    }
    
    // Handling panning gesture inside StampSelector view
    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        // Move stamp selector down / up if necessary - x coordinate is ignored
        stampSelectorBottomContstraint.constant = Specs.bottomButtonsMargin - translation.y
        
        // When gesture ended - see if passed threshold - dismiss the view otherwise
        // roll back to the full state
        if gesture.state == .ended {
            if translation.y > stampSelector.bounds.height / 2 {
                onCloseStampSelectorTapped?()
            } else {
                // Rollback and show full stamp selector 
                showStampSelector(.fullSelector)
            }
        }
    }
    
    // MARK: - Private helpers

    private func adjustButtonConstraintsForState(_ state: SelectorState) {
        stampSelectorBottomContstraint.constant = (state == .fullSelector) ?
            Specs.bottomButtonsMargin :
            -(stampSelector.bounds.height + Specs.bottomButtonsMargin)
        
        plusButtonBottomContstraint.constant = (state == .miniButton) ?
            Specs.bottomButtonsMargin :
            -(plusButton.bounds.height + Specs.bottomButtonsMargin)
        view.layoutIfNeeded()
    }
    
    private func configureViews() {
        // Hide buttons initially
        adjustButtonConstraintsForState(.hidden)
        
        prevWeek.image = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))!
        nextWeek.image = UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))!

        selectedDayIndicator.layer.cornerRadius = selectedDayIndicator.bounds.height / 2
        selectedDayIndicator.backgroundColor = UIColor.systemGray3
        selectedDayIndicator.clipsToBounds = true
        
        stampSelector.onStampTapped = { (stampId) in
            self.onStampInSelectorTapped?(stampId)
        }
        stampSelector.onNewStickerTapped = { () in
            self.onNewStickerTapped?()
        }
        daysHeader.onDayTapped = { (index) in
            self.onDayHeaderTapped?(index)
        }
        day0.onDayTapped = { () in
            self.onDayHeaderTapped?(0)
        }
        day1.onDayTapped = { () in
            self.onDayHeaderTapped?(1)
        }
        day2.onDayTapped = { () in
            self.onDayHeaderTapped?(2)
        }
        day3.onDayTapped = { () in
            self.onDayHeaderTapped?(3)
        }
        day4.onDayTapped = { () in
            self.onDayHeaderTapped?(4)
        }
        day5.onDayTapped = { () in
            self.onDayHeaderTapped?(5)
        }
        day6.onDayTapped = { () in
            self.onDayHeaderTapped?(6)
        }
        
        plusButton.layer.shadowRadius = Specs.shadowRadius
        plusButton.layer.shadowOpacity = Specs.shadowOpacity
        plusButton.layer.shadowColor = UIColor.gray.cgColor
        plusButton.layer.shadowOffset = Specs.shadowOffset
        plusButton.layer.cornerRadius = Specs.miniButtonCornerRadius
        plusButton.backgroundColor = UIColor.systemGray6
    }
}

// MARK: - TodayCoordinator

extension TodayViewController: TodayCoordinator {
    
    func newSticker() {
        performSegue(withIdentifier: UIStoryboardSegue.newSticker, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {

        case UIStoryboardSegue.newSticker:
            guard let controller = (segue.destination as? UINavigationController)?.viewControllers.first as? StampViewController else { return }

            setEditing(false, animated: true)
            controller.stamp = Stamp.defaultStamp
            controller.presentationMode = .modal
        
        default:
            break
        }
    }
}

// MARK: - Specs
fileprivate struct Specs {
    
    /// Stamp selector mini button corner radius
    static let miniButtonCornerRadius: CGFloat = 8.0
    
    /// Bottom buttons (both full and small) margin from the edge
    static let bottomButtonsMargin: CGFloat = 16.0

    /// Shadow radius
    static let shadowRadius: CGFloat = 8.0
    
    /// Shadow opacity
    static let shadowOpacity: Float = 0.4
    
    /// Shadow offset
    static let shadowOffset = CGSize.zero
}
