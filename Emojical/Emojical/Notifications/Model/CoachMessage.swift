//
//  CoachMessage.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 3/14/21.
//  Copyright © 2021 Vladimir Svidersky. All rights reserved.
//

import Foundation

enum CoachMessage {
    
    /// First onboarding message about stickers
    case onboarding1
    
    /// Second onboarding message about goals
    case onboarding2
    
    /// Week is closed, ready to view recap
    case weekReady(String)
    
    /// Cheers when positive goal is reached
    case cheerGoalReached(Award)
}
