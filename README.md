# JRLongPressGestureHandler

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

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
      self.longPress.addTarget(self, action: #selector(longPressGestureRecognized(_:)))
      self.tableView.addGestureRecognizer(longPress)
    }

    func longPressGestureRecognized(gesture: UILongPressGestureRecognizer) {
      gestureHandler.longPressGestureRecognized(self.tableView, gesture: gesture)
    }

You'll now want to specify the handler's protocol in your UITableViewController's declaration:

    class TableViewController: UITableViewController, JRLongPressGestureHandlerDelegate

To conform to the protocol, you'll need to implement the following function:

    func didEndLongPress(startIndexPath: NSIndexPath, endIndexPath: NSIndexPath) { {
      // You will want to update your datasource to swap
      // the items located at these positions
    }
