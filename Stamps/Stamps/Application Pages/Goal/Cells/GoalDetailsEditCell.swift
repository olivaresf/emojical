//
//  GoalDetailsEditCell.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/24/2020.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class GoalDetailsEditCell: UICollectionViewCell {

    // MARK: - Outlets

    @IBOutlet weak var plate: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var name: UITextField!

    @IBOutlet weak var limitLabel: UILabel!
    @IBOutlet weak var limit: UITextField!
    @IBOutlet weak var limitExplanation1: UILabel!
    @IBOutlet weak var limitExplanation2: UILabel!

    @IBOutlet weak var stickersLabel: UILabel!
    @IBOutlet weak var stickers: UILabel!
    @IBOutlet weak var selectStickersButton: UIButton!

    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var direction: UISegmentedControl!

    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var period: UISegmentedControl!

    /// User changed any value
    var onValueChanged: (() -> Void)?

    /// User tapped on list of stickers
    var onSelectStickersTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tap)
    }
    
    // MARK: - Public view interface

    func configure(for data: GoalEditData) {
        name.text = data.goal.name
        limit.text = "\(data.goal.limit)"
        
        let stickersText = data.stickers.joined(separator: ", ")
        if stickersText.lengthOfBytes(using: .utf8) > 0 {
            stickers.text = stickersText
        } else {
            stickers.text = "Select one or more"
        }
        direction.selectedSegmentIndex = data.goal.direction.rawValue
        period.selectedSegmentIndex = data.goal.period.rawValue
        directionChanged(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    // MARK: - Actions
    
    @IBAction func selectStickersButtonTapped(_ sender: Any) {
        onSelectStickersTapped?()
    }

    @IBAction func directionChanged(_ sender: Any) {
        let positive = direction.selectedSegmentIndex == 0
        limitLabel.text = positive ? "Goal:" : "Limit:"
        limitExplanation2.text = positive ? "or more" : "or fewer"
        onValueChanged?()
    }
    
    @IBAction func periodChanged(_ sender: Any) {
        onValueChanged?()
    }

    // MARK: - Private helpers

    private func configureViews() {
        plate.backgroundColor = UIColor.clear
        
        let labels: [UILabel] = [nameLabel, limitLabel, stickersLabel, directionLabel, periodLabel, limitExplanation1, limitExplanation2]
        for label in labels {
            label.font = Theme.shared.fonts.formFieldCaption
            label.textColor = Theme.shared.colors.secondaryText
        }

        nameLabel.text = "Name:"
        name.backgroundColor = UIColor.systemGray6
        name.font = Theme.shared.fonts.listBody
        
        stickersLabel.text = "Stickers:"
        stickers.font = Theme.shared.fonts.listBody
        
        limitLabel.text = "Goal:"
        limitExplanation1.text = "get"
        limitExplanation2.text = "or more"
        
        limit.backgroundColor = UIColor.systemGray6
        limit.font = Theme.shared.fonts.listBody
        
        periodLabel.text = "Goal Period:"
        directionLabel.text = "Direction:"
    }
    
    @IBAction func textChanged(_ sender: Any) {
        onValueChanged?()
    }

    @objc func viewTapped(sender: UITapGestureRecognizer) {
        let loc = sender.location(in: stickers)
        if stickers.bounds.contains(loc) {
            onSelectStickersTapped?()
        }
    }
}
