# JRLongPressGestureHandler

This framework was originally a translation of *UILongPressGestureRecognizer*, written in Objective-C, found at [https://github.com/moayes/UDo/](https://github.com/moayes/UDo/) (as appeared on [Ray Wenderlich](https://www.raywenderlich.com/63089/cookbook-moving-table-view-cells-with-a-long-press-gesture)) and I've since brought a few improvements so I bundled it to be easily reused in other iOS projects by others.

## Preview
![JRLongPressGestureHandler preview](https://cloud.githubusercontent.com/assets/5186556/15262368/eb0cd2d2-192f-11e6-8fde-72444c20d5c6.gif)

## Install
Using [Carthage](https://github.com/Carthage/Carthage):

Add `github "jeremyrea/JRLongPressGestureHandler"` to your Cartfile and run `carthage update`.

Drag and drop the newly created *JRLongPressGestureHandler.framework* and *JRLongPressGestureHandler.dSYM* files found in `$projectRoot/Carthage/Build/iOS/` into your project in Xcode.

The final step is adding the framework to your project's Embedded Binaries.

## Usage
In your UITableViewController:

    import JRLongPressGestureHandler

Create your touch recognizer at the top of the class:

    private let longPress: UILongPressGestureRecognizer = {
      let recognizer = UILongPressGestureRecognizer()
      return recognizer
    }()

    private var gestureHandler: JRLongPressGestureHandler!


    required init? (coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      // ...
      gestureHandler = JRLongPressGestureHandler(delegate: self)
    }

    override func viewDidLoad() {
      // ...
      self.longPress.addTarget(self, action: #selector(longPressGestureRecognized(\_:)))
      self.tableView.addGestureRecognizer(longPress)
    }

You'll now need to specify the handler's protocol in your UITableViewController's declaration:

    class TableViewController: UITableViewController, JRLongPressGestureHandlerDelegate

To conform to the protocol, you'll finally need to implement the following functions:

    func longPressGestureRecognized(gesture: UILongPressGestureRecognizer) {
      gestureHandler.longPressGestureRecognized(self.tableView, gesture: gesture)
    }

    func updateDataSource(sourceRow: Int, destinationRow: Int) {
      // This method is called while the long press hasn't
      // yet been released

      // Swap here the items at the returned indexes in your
      // tableView's datasource so that your cells don't get
      // mixed up
    }

    func savePosition(startRow: Int, endRow: Int) {
      // This method is called once the long press has been
      // released and the cell is set back down

      // You may want to save changes done to the data
      // source to your persistent store
    }
