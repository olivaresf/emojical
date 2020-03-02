//
//  DataSource+Goal.swift
//  Stamps
//
//  Created by Vladimir Svidersky on 1/20/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import Foundation
import GRDB

// MARK: - Goals Helper Methods
extension DataSource {

    // Single Goal object by Id
    func goalById(_ identifier: Int64) -> Goal? {
        do {
            return try dbQueue.read { db -> Goal? in
                let request = Goal.filter(Goal.Columns.id == identifier)
                return try request.fetchOne(db)
            }
        }
        catch { }
        return nil
    }

    // Count for specific goal/award in Diary table
    func goalCountById(_ identifier: Int64) -> Int {
        do {
            return try dbQueue.read { db -> Int in
                let request = Award.filter(Award.Columns.goalId == identifier)
                return try request.fetchCount(db)
            }
        }
        catch { }
        return 0
    }

    // Last used stamp date from Diary
    func goalLastUsed(_ identifier: Int64) -> String? {
        do {
            return try dbQueue.read { db -> String? in
                let request = Award.filter(Award.Columns.goalId == identifier).order(Award.Columns.date.desc)
                return try request.fetchOne(db)?.date
            }
        }
        catch { }
        return nil
    }

    // All goals
    func allGoals() -> [Goal] {
        do {
            return try dbQueue.read { db -> [Goal] in
                let request = Goal.filter(Goal.Columns.deleted == false).order(Goal.Columns.name)
                return try request.fetchAll(db)
            }
        }
        catch { }
        return []
    }

    // Recalculate count and lastUsed in Goal object
    func updateStatsForGoals(_ ids: [Int64]) {
        for id in ids {
            if var goal = goalById(id) {
                goal.count = goalCountById(id)
                goal.lastUsed = goalLastUsed(id) ?? ""
                do {
                    try dbQueue.write { db in
                        try goal.update(db)
                    }
                }
                catch { }
            }
        }
    }

    // Recalculate all Goals
    func recalculateAllGoals() {
        let goals = allGoals()
        updateStatsForGoals(goals.map({ $0.id! }))
    }

    // Goals by period
    func goalsByPeriod(_ period: Goal.Period) -> [Goal] {
        do {
            return try dbQueue.read { db -> [Goal] in
                let request = Goal.filter(Goal.Columns.period == period)
                return try request.fetchAll(db)
            }
        }
        catch { }
        return []
    }
}