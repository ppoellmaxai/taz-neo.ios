//
//  die_tageszeitungUITests.swift
//  die tageszeitungUITests
//
//  Created by Philo.Pöllmann on 1/18/21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import XCTest
class taz_neo_UITests: XCTestCase {
    
    //static var app:XCUIApplication {return XCUIApplication()}
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the  class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testHelpPopUp(app: XCUIApplication) throws {
        // Testing Help functionality in login window
        let app = XCUIApplication()
        app.launch()
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery/*@START_MENU_TOKEN@*/.staticTexts["Hilfe"]/*[[".buttons[\"Hilfe\"].staticTexts[\"Hilfe\"]",".staticTexts[\"Hilfe\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts["Hilfe"].scrollViews.otherElements.buttons["OK"].tap()
    }
    
    func testAuthentification(app: XCUIApplication) throws {
        // Authentification in case user is not authenticated

        let authenticated = !app.textFields["E-Mail-Adresse oder Abo-ID"].exists
        
        if(!authenticated){
            do{
                let elementsQuery = app.scrollViews.otherElements
                elementsQuery.textFields["E-Mail-Adresse oder Abo-ID"].tap()
                elementsQuery.textFields["E-Mail-Adresse oder Abo-ID"].typeText(TestConstants.testmailAdress)
                elementsQuery.secureTextFields["Passwort"].tap()
                elementsQuery.secureTextFields["Passwort"].typeText(TestConstants.testPW)

                elementsQuery/*@START_MENU_TOKEN@*/.staticTexts["Anmelden"]/*[[".buttons[\"Anmelden\"].staticTexts[\"Anmelden\"]",".staticTexts[\"Anmelden\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            }
        }
        XCTAssertFalse(app.textFields["E-Mail-Adresse oder Abo-ID"].exists)
    }
    
    func testCarousel(app: XCUIApplication) throws {
        //test if regular swipe increases issue index by 2
        
        let firstIssue = app.collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element
        XCTAssertTrue(firstIssue.isHittable)
        
        firstIssue.swipeLeft()
        XCTAssertFalse(firstIssue.isHittable)
        
        let thirdIssue = app.collectionViews.otherElements["Ausgabe:2"].children(matching: .image).element
        XCTAssertTrue(thirdIssue.isHittable)
        
        thirdIssue.swipeRight()
        XCTAssertTrue(firstIssue.isHittable)
    }
    
    func testSidebar(app: XCUIApplication) throws {
        app.collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element.tap()

        let logoButton = app.buttons["logo"]
        let tablesQuery = app.tables
        
        //TODO will fail for weekend edition, think of sth better and more stable
        let pages = ["titel", "der tag", "Impressum"]
        for page in pages {
            logoButton.tap()
            tablesQuery.staticTexts[page].tap()
        }
        let homeButton = app.toolbars["Toolbar"].children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 2)
        homeButton.tap()
    }
    
    func testHomeButton(app: XCUIApplication) throws {
        let issue = app.collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element
        let homeButton = app/*@START_MENU_TOKEN@*/.toolbars["Toolbar"]/*[[".toolbars[\"Symbolleiste\"]",".toolbars[\"Toolbar\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 2)
        issue.tap()
        homeButton.tap()
        XCTAssertTrue(issue.isHittable)
    }

    func testNightmode(app: XCUIApplication) throws {
        let issue = app.collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element
        let fontButton = app/*@START_MENU_TOKEN@*/.toolbars["Toolbar"]/*[[".toolbars[\"Symbolleiste\"]",".toolbars[\"Toolbar\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element(boundBy: 1)
        issue.tap()
        fontButton.tap()
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
    }
    
    func testGoldenPath() {
        let app = XCUIApplication("de.taz.taz.2")
        app.launch()
        
        //wait for carousel to appear and be initialized in the right position
        let predicate = NSPredicate(format: "exists == 1")
        let query = XCUIApplication().collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element
        expectation(for:predicate, evaluatedWith: query, handler: nil)

        waitForExpectations(timeout:30, handler: nil)
    do{
            //  try testAuthentification(app:app)
            try testCarousel(app:app)
            try testSidebar(app:app)
            try testHomeButton(app:app)
            try testNightmode(app:app)
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

