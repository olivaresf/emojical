//
//  OptionsViewController.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/17/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class OptionsViewController: BaseTableViewController, OptionsView {

    // MARK: - DI

    var presenter: OptionsPresenterProtocol!

    lazy var coordinator: OptionsCoordinatorProtocol = {
        OptionsCoordinator(
            parent: self.navigationController!
        )
    }()

    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = OptionsPresenter(
            view: self,
            settings: LocalSettings.shared,
            coordinator: coordinator)
        
        configureViews()
        presenter.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.onViewWillAppear()
    }

    // MARK: - OptionsView
    
    /// Return UIViewController instance (so we can present and mail stuff from Presenter class)
    var viewController: UIViewController? {
        return self
    }
    
    /// Load view data
    func loadData(_ sections: [OptionsSection]) {
        self.sections = sections
        var snapshot = NSDiffableDataSourceSnapshot<OptionsSection, OptionsCell>()
        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.cells)
        }
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }

    // MARK: - Private helpers
    
    private func configureViews() {
        configureTableView()
    }
}
