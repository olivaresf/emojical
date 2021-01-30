//
//  NewGoalCell.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/10/2020.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class NewGoalCell: UICollectionViewCell {

    // MARK: - Outlets

    @IBOutlet weak var plate: UIView!
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    // MARK: - Public view interface

    func configure() {
    }

    // MARK: - Private helpers

    private func configureViews() {
        plate.layer.cornerRadius = Specs.cornerRadius
        plate.layer.borderWidth = Specs.borderWidth
        plate.backgroundColor = UIColor.clear
        plate.layer.borderColor = UIColor.systemGray6.cgColor
        plate.clipsToBounds = true

        title.font = Theme.shared.fonts.boldButtons
        title.text = "Create Goal"
    }
}

// MARK: - Specs
fileprivate struct Specs {
    
    /// Background corner radius
    static let cornerRadius: CGFloat = 8.0

    /// Border width
    static let borderWidth: CGFloat = 2.0
}
