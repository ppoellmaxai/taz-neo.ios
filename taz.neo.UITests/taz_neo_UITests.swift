//
//  die_tageszeitungUITests.swift
//  die tageszeitungUITests
//
//  Created by Philo.Pöllmann on 1/18/21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import XCTest
class taz_neo_UITests: XCTestCase {
        
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the  class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func _testAuthentification() throws {
        let authenticated = !AppElements.eMailTextField.exists
        
        if(!authenticated){
            do{
                AppElements.eMailTextField.tap()
                AppElements.eMailTextField.typeText(TestConstants.testmailAdress)
                AppElements.passwordTextField.tap()
                AppElements.passwordTextField.typeText(TestConstants.testPW)
                AppElements.signInBtn.tap()
            }
        }
        XCTAssertFalse(AppElements.eMailTextField.exists)
    }
    
    func _testCarousel() throws {
        //test if regular swipe increases issue index by 2
        XCTAssertTrue(AppElements.firstIssue.isHittable)
        AppElements.firstIssue.swipeLeft()
        XCTAssertFalse(AppElements.firstIssue.isHittable)
        XCTAssertTrue(AppElements.thirdIssue.isHittable)
        
        AppElements.thirdIssue.swipeRight()
        XCTAssertTrue(AppElements.firstIssue.isHittable)
    }
    
    func _testSidebar() throws {
        AppElements.firstIssue.tap()
        
        //needs to wait for the sidebar animation to have taken place
        sleep(10)
        
        //TODO will possibly fail for weekend edition, think of sth better and more stable
        let pages = ["Impressum", "titel"]
        for page in pages {
            AppElements.logoBtn.tap()
            AppElements.sideBarTbl.staticTexts[page].tap()
        }
        AppElements.homeBtn.tap()
    }
    
    func _testHomeButton() throws {
        AppElements.firstIssue.tap()
        XCTAssertFalse(AppElements.firstIssue.isHittable)
        
        AppElements.homeBtn.tap()
        XCTAssertTrue(AppElements.firstIssue.isHittable)
    }

    func _testFontButton() throws {
        AppElements.firstIssue.tap()
        AppElements.fontBtn.tap()
        //some assert
    }
    
    func testGoldenPath() {
        let app = XCUIApplication().launch()
        let foundElement = waitForEitherElementToExist(elementA: AppElements.gdprHeader, elementB: AppElements.firstIssue, timeout: 30)

        if(foundElement == AppElements.gdprHeader){
            do{
                AppElements.gdprHeader.swipeUp()
                AppElements.gdprHeader.swipeUp()
                AppElements.acceptGdprBtn.tap()
                AppElements.welcomeXBtn.tap()
                waitForElementToExist(test: self, element: AppElements.firstIssue)
            }
        }
    
        do{
            try _testCarousel()
            try _testSidebar()
            try _testHomeButton()
            try _testFontButton()
            try _testAuthentification()
        }
        catch let error {
            print(error.localizedDescription)
            }
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

}
