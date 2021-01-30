//
//  DevelopmentViewController.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/30/21.
//  Copyright © 2021 Vladimir Svidersky. All rights reserved.
//

import UIKit

class DevelopmentViewController: BaseTableViewController, DevelopmentView {

    // MARK: - DI

    var presenter: DevelopmentPresenterProtocol!

    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter = DevelopmentPresenter(
            view: self,
            settings: LocalSettings.shared
        )
        
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
