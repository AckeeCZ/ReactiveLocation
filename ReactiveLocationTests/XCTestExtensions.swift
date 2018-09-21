//
//  XCTestExtensions.swift
//  ReactiveLocationTests
//
//  Created by Jakub Olejník on 21/09/2018.
//

import XCTest

extension XCTestCase {
    func async(timeout: TimeInterval = 0.5, testBlock: ((XCTestExpectation) -> ())) {
        let expectation = self.expectation(description: name)
        print(expectation)
        testBlock(expectation)
        waitForExpectations(timeout: timeout, handler: {
            if let error = $0 { XCTFail(error.localizedDescription) }
        })
    }
}
