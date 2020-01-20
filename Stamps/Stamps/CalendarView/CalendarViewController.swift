//
//  CalendarViewController.swift
//  Stamps
//
//  Created by Vladimir Svidersky on 1/17/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import UIKit

class CalendarViewController: UITableViewController {

    var data = CalenderHelper.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.numberOfMonths
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.numberOfWeeksIn(month: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data.textForMonth(section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "weekCell") as! WeekCell
        cell.loadData(data.textForWeek(month: indexPath.section, week: indexPath.row), indexPath: indexPath)
        cell.delegate = self
        return cell
    }

    // Specific day of the month selected
    func daySelected(month: Int, day: Int) {
        // print(data.textForMonth(month), day)

        // Load and configure your view controller.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dayDetail = storyboard.instantiateViewController(
                  withIdentifier: "dayDetail") as! DayViewController
        
        dayDetail.monthTitle.text = data.textForMonth(month)
        dayDetail.dayTitle.text = "\(day)"
        
        // Use the popover presentation style for your view controller.
        dayDetail.modalPresentationStyle = .overFullScreen
        dayDetail.modalTransitionStyle = .coverVertical
        
        // Present the view controller (in a popover).
        self.present(dayDetail, animated: true) {
          // The popover is visible.
        }
    }
}

extension CalendarViewController : WeekCellDelegate {
    
    func dayTapped(_ day: Int, indexPath: IndexPath) {
        let d = data.dayInMonth(month: indexPath.section, week: indexPath.row, day: day)
        if d != nil {
            daySelected(month: indexPath.section, day: d!)
        }
    }
}
