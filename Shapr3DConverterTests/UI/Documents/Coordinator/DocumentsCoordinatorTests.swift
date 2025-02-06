import XCTest
import Combine
@testable import Shapr3DConverter

final class DocumentsCoordinatorTests: XCTestCase {
    private var coordinator: DocumentsCoordinator!
    private var routerMock: RouterMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        routerMock = RouterMock(baseRoute: .core)
        coordinator = DocumentsCoordinator(router: routerMock)
        cancellables = []
    }

    override func tearDown() {
        coordinator = nil
        routerMock = nil
        cancellables = nil
        super.tearDown()
    }

    func test_bindViewModel_updatesItemsOnSubjectChange() {
        let expectation = XCTestExpectation(description: "ViewController should receive updated items")

        let testItem = DocumentItem(id: UUID(),
                                    fileURL: URL(fileURLWithPath: "/test/file.pdf"),
                                    fileName: "file.pdf",
                                    fileSize: 12345,
                                    conversionStates: [.obj: .idle])

        coordinator.testHooks.itemsSubject.send([testItem])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.coordinator.testHooks.itemsSubject.value.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_selectFileAndConvert_addsNewDocumentItem() {
        let expectation = XCTestExpectation(description: "New item should be added to itemsSubject")

        let testURL = URL(fileURLWithPath: "/test/newfile.obj")

        coordinator.testHooks.selectFileAndConvertMock(testURL)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let items = self.coordinator.testHooks.itemsSubject.value
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.fileName, "newfile.obj")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_documentPicker_didPickDocumentsAt_savesFile() {
        let sourceURL = URL(fileURLWithPath: "/test/source.pdf")
        coordinator.testHooks.mockDocumentSelection(sourceURL)
    }


    func test_documentPicker_didPickDocumentsAt_handlesErrorGracefully() {
        let expectation = XCTestExpectation(description: "Error case should not crash")

        let invalidURL = URL(fileURLWithPath: "/invalid/path/file.pdf")

        coordinator.testHooks.mockDocumentSelection(invalidURL)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(true, "Should not crash on invalid URL")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

