//
//  DataSource+Stamp.swift
//  Stamps
//
//  Created by Vladimir Svidersky on 1/20/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//
import Foundation
import GRDB

// MARK: - Stamps Helper Methods
extension DataSource {

    // Single stamp object
    func stampById(_ identifier: Int64) -> Stamp? {
        do {
            return try dbQueue.read { db -> Stamp? in
                let request = Stamp.filter(Stamp.Columns.id == identifier)
                return try request.fetchOne(db)
            }
        }
        catch { }
        return nil
    }
    
    // Count for specific stamp in Diary table
    func stampCountById(_ identifier: Int64) -> Int {
        do {
            return try dbQueue.read { db -> Int in
                let request = Diary.filter(Diary.Columns.stampId == identifier)
                return try request.fetchCount(db)
            }
        }
        catch { }
        return 0
    }

    // Last used stamp date from Diary
    func stampLastUsed(_ identifier: Int64) -> String? {
        do {
            return try dbQueue.read { db -> String? in
                let request = Diary.filter(Diary.Columns.stampId == identifier).order(Diary.Columns.date.desc)
                return try request.fetchOne(db)?.date
            }
        }
        catch { }
        return nil
    }

    // Only favorites stamps - used in day view
    func favoriteStamps() -> [Stamp] {
        do {
            return try dbQueue.read { db -> [Stamp] in
                let request = Stamp.filter(Stamp.Columns.favorite == true).order(Stamp.Columns.name)
                return try request.fetchAll(db)
            }
        }
        catch { }
        return []
    }

    // All stamps
    func allStamps() -> [Stamp] {
        do {
            return try dbQueue.read { db -> [Stamp] in
                let request = Stamp.filter(Stamp.Columns.deleted == false).order(Stamp.Columns.name)
                return try request.fetchAll(db)
            }
        }
        catch { }
        return []
    }

    // Stamp Ids for a day (will be stored in Diary table)
    func stampsIdsForDay(_ day: Date) -> [Int64] {
        do {
            return try dbQueue.read { db in
                let request = Diary.filter(Diary.Columns.date == day.databaseKey).order(Stamp.Columns.id)
                let allrecs = try request.fetchAll(db)
                return allrecs.map({ $0.stampId })
            }
        }
        catch { }
        return []
    }

    // Recalculate count and lastUsed in Stamp object
    func updateStatsForStamps(_ stampIds: [Int64]) {
        for id in stampIds {
            if var stamp = stampById(id) {
                stamp.count = stampCountById(id)
                stamp.lastUsed = stampLastUsed(id) ?? ""
                do {
                    try dbQueue.write { db in
                        try stamp.update(db)
                    }
                }
                catch { }
            }
        }
    }
    
    // Recalculate all Stamps
    func recalculateAllStamps() {
        let stamps = allStamps()
        updateStatsForStamps(stamps.map({ $0.id! }))
    }

}