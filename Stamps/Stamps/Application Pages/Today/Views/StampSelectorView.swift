//
//  StampSelectorView.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 12/06/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class StampSelectorView : UIView {

    // MARK: - UI Outlets
    
    @IBOutlet weak var stamps: UICollectionView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    // MARK: - State
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, DayStampData>!
    
    // MARK: - Callbacks
    
    var onStampTapped: ((Int64) -> Void)?

    // MARK: - View lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    // MARK: - Public view interface

    func loadData(data: [DayStampData]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DayStampData>()
        snapshot.appendSections([0])
        
        snapshot.appendItems(data)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        
        // Arrange stamps in row by [stampsPerRow]. If we have fewer than [stampsPerRow],
        // center them inside selector view.
        // Otherwise make width to [stampsPerRow] elements, and number of row to 2
        // Will have to improve when more then 10 stamps are supported
        if data.count <= Specs.stampsPerRow {
            heightConstraint.constant = Specs.stampSize
            widthConstraint.constant = Specs.stampSize * CGFloat(data.count)
        } else if data.count <= Specs.stampsPerRow * 2 {
            heightConstraint.constant = Specs.stampSize * 2
            widthConstraint.constant = Specs.stampSize * CGFloat(Specs.stampsPerRow)
        }
    }
    
    // MARK: - Private helpers
    
    private func setupViews() {
        // Background view
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = Specs.plateCornerRadius
        clipsToBounds = true
        
        // Collection view for stamps
        configureCollectionView()
        registerCells()
    }
    
    private func registerCells() {
        stamps.register(
            UINib(nibName: "DayStampCell", bundle: .main),
            forCellWithReuseIdentifier: Specs.Cells.stamp
        )
    }

    private func configureCollectionView() {
        self.dataSource = UICollectionViewDiffableDataSource<Int, DayStampData>(
            collectionView: stamps,
            cellProvider: { [weak self] (collectionView, path, model) -> UICollectionViewCell? in
                self?.cell(for: path, model: model, collectionView: collectionView)
            }
        )

        stamps.dataSource = dataSource
        stamps.delegate = self
        stamps.collectionViewLayout = stampsSelectorLayout()
        stamps.backgroundColor = UIColor.clear
        stamps.alwaysBounceHorizontal = false
        stamps.alwaysBounceVertical = false
    }
    
    // Creates layout for the day column - vertical list of cells
    private func stampsSelectorLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(Specs.stampSize),
                heightDimension: .absolute(Specs.stampSize)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(Specs.stampSize)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension StampSelectorView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let stampId = collectionView.cellForItem(at: indexPath)?.tag else { return }
        onStampTapped?(Int64(stampId))
    }
    
    private func cell(for path: IndexPath, model: DayStampData, collectionView: UICollectionView) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Specs.Cells.stamp, for: path
        ) as? DayStampCell else { return UICollectionViewCell() }
        
        cell.configure(for: model, insets: Specs.stampInsets)
        return cell
    }
}

// MARK: - Specs
fileprivate struct Specs {
    
    /// Cell identifiers
    struct Cells {
        
        /// Stamp cell
        static let stamp = "DayStampCell"
    }
    
    /// Stamp cell size
    static let stampSize: CGFloat = 60.0
    
    /// Stamp row size
    static let stampsPerRow = 5
    
    /// Actual stamp insets inside the stamp cell
    static let stampInsets = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)

    /// Background plate corner radius
    static let plateCornerRadius: CGFloat = 8.0
}