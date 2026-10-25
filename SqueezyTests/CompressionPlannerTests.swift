//
//  CompressionPlannerTests.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Testing
@testable import Squeezy

struct CompressionPlannerTests {
    @Test func plansStayWithingTargetBudget() {
        let planner = CompressionPlanner()
        let plans = planner.makePlans(duration: 7200, hasAudio: true)
        
        #expect(plans.count == 3)
        
        for plan in plans {
            #expect(plan.estimatedBytes <= plan.targetBytes)
            #expect(plan.videoBitrate >= 0)
        }
    }
    
    @Test func longerVideoGetsLowerBitrate() {
        let planner = CompressionPlanner()
        
        let short = planner.makePlans(duration: 3600, hasAudio: true)
        let long = planner.makePlans(duration: 7200, hasAudio: true)
        
        #expect(short[1].videoBitrate > long[1].videoBitrate)
    }
    
    @Test func audioBudgetIsZeroWhenMissing() {
        let plans = CompressionPlanner().makePlans(duration: 3600, hasAudio: false)
        
        #expect(plans.allSatisfy {
            $0.audioBitrate == 0
        })
    }
    
    @Test func invalidDurationProducesNoPlans() {
        let planner = CompressionPlanner()
        
        #expect(planner.makePlans(duration: 0, hasAudio: true).isEmpty)
        #expect(planner.makePlans(duration: -.infinity, hasAudio: true).isEmpty)
        #expect(planner.makePlans(duration: .nan, hasAudio: true).isEmpty)
    }
}
