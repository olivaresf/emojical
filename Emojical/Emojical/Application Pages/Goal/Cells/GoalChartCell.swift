//
//  GoalDetailsCell.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/24/2020.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class GoalChartCell: UICollectionViewCell {

    // MARK: - Outlets

    @IBOutlet weak var plate: UIView!
    @IBOutlet weak var chart: GoalChartView!
    @IBOutlet weak var header: UILabel!

    // MARK: - State

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    // MARK: - Public view interface

    func configure(for data: [GoalHistoryPoint]) {
        
        chart.data = data
        chart.dataMax = data.map({ $0.total }).max() ?? 0
        chart.dataThreshold = data.first?.limit ?? 0
        chart.count = 12
        
        header.text = "Last 12 weeks".uppercased()
    }
    
    // MARK: - Private helpers

    private func configureViews() {
        plate.backgroundColor = Theme.main.colors.secondaryBackground
        plate.layer.cornerRadius = Theme.main.specs.platesCornerRadius
        plate.clipsToBounds = true
        chart.backgroundColor = Theme.main.colors.secondaryBackground
        
        header.font = Theme.main.fonts.sectionHeaderTitle
        header.textColor = Theme.main.colors.sectionHeaderText
    }
}
