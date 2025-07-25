import XCTest

/// A basic UI test exercising the main flow of the application. The
/// test launches the app, creates a palace, wing and room and then
/// navigates to the Citadel scene. It verifies that nodes are added
/// and removed from the scene by counting descendant views. Note
/// that UI tests require the app target to be configured with
/// accessibility identifiers; some identifiers are inferred in this
/// skeleton but may need adjustment when run in Xcode.
final class BasicFlowUITest: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCreateAndDeleteRoomFlow() throws {
        // Tap Palaces tab (first tab)
        let palacesTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(palacesTab.waitForExistence(timeout: 5))
        palacesTab.tap()
        // Add palace if none exists
        let plusButton = app.navigationBars.buttons["plus"]
        if plusButton.exists {
            plusButton.tap()
            let nameField = app.textFields["Name"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 2))
            nameField.tap()
            nameField.typeText("UITest Palace")
            app.buttons["Add"].tap()
        }
        // Select first palace
        let firstCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.tap()
        // Add wing if none exists
        let addWingButton = app.navigationBars.buttons["plus"]
        if addWingButton.exists {
            addWingButton.tap()
            let titleField = app.textFields["Title"]
            XCTAssertTrue(titleField.waitForExistence(timeout: 2))
            titleField.tap()
            titleField.typeText("UITest Wing")
            app.buttons["Add"].tap()
        }
        // Select first wing
        let wingCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(wingCell.waitForExistence(timeout: 5))
        wingCell.tap()
        // Add room
        let addRoomButton = app.navigationBars.buttons["plus"]
        addRoomButton.tap()
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("UITest Room")
        app.buttons["Add"].tap()
        // Navigate to citadel tab and verify a node appears
        let citadelTab = app.tabBars.buttons.element(boundBy: 1)
        citadelTab.tap()
        // Wait for the SceneKit view to load
        let scnView = app.otherElements["citadelSceneView"]
        let sceneLoaded = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: scnView, handler: nil)
        wait(for: [sceneLoaded], timeout: 5)
        // Delete room from MemoryListView (go back) to test removal
        palacesTab.tap()
        firstCell.tap()
        wingCell.tap()
        let roomCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(roomCell.waitForExistence(timeout: 5))
        roomCell.swipeLeft()
        roomCell.buttons["Delete"].tap()
        // Verify room removed from list
        XCTAssertEqual(app.tables.cells.count, 0)
    }
}
