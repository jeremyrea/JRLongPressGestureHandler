import UIKit

public protocol JRLongPressGestureHandlerDelegate: class {
  func didEndLongPress(startIndex: Int, endIndex: Int)
}

public class JRLongPressGestureHandler {
  
  enum CellAlpha: CGFloat {
    case Hidden = 0.0
    case Visible = 1.0
  }
  
  private weak var delegate: JRLongPressGestureHandlerDelegate?
  private var snapshot: UIView?
  private var sourceIndexPath: NSIndexPath?
  private var previousIndexPath: NSIndexPath?
  private var backupIndexPath: NSIndexPath?
  private var startIndex: Int!
  
  public init(delegate: JRLongPressGestureHandlerDelegate) {
    self.delegate = delegate
  }
  
  public func longPressGestureRecognized(tableView: UITableView, gesture: UILongPressGestureRecognizer) {
    let gestureState: UIGestureRecognizerState = gesture.state
    let location: CGPoint = gesture.locationInView(tableView)
    var indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
    
    if cellIsOutOfBounds(indexPath) {
      indexPath = self.backupIndexPath
    } else if cellWasOutOfBounds(tableView.numberOfRowsInSection(0), indexPath: indexPath!) {
      self.backupIndexPath = indexPath
    }
    
    switch (gestureState) {
    case UIGestureRecognizerState.Began:
      sourceIndexPath = indexPath
      startIndex = sourceIndexPath!.row
      pickupCellAnimation(tableView, indexPath: indexPath!, location: location)
      
    case UIGestureRecognizerState.Changed:
      var center: CGPoint = snapshot!.center
      center.y = location.y
      snapshot?.center = center
      
      if cellMoved(sourceIndexPath!, indexPath: indexPath!) {
        displaceCellAnimation(tableView, indexPath: indexPath!)
      }
      
      self.previousIndexPath = indexPath
      
    default:
      depositCellAnimation(tableView, indexPath: indexPath!)
      delegate!.didEndLongPress(startIndex, endIndex: indexPath!.row)

      break
    }
  }
  
  private func cellIsOutOfBounds(indexPath: NSIndexPath?) -> Bool {
    return indexPath == nil && backupIndexPath != nil
  }
  
  private func cellWasOutOfBounds(tableSize: Int, indexPath: NSIndexPath) -> Bool {
    return (indexPath.row == 0 || indexPath.row == tableSize - 1)
  }
  
  private func cellMoved(sourceIndexPath: NSIndexPath, indexPath: NSIndexPath) -> Bool {
    return indexPath != sourceIndexPath
  }
  
  private func hideCell(tableView: UITableView, indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    cell.alpha = CellAlpha.Hidden.rawValue
  }
  
  private func pickupCellAnimation(tableView: UITableView, indexPath: NSIndexPath, location: CGPoint) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    var centerPoint = cell.center
    snapshot = customSnapshotFromView(cell, snapshotCenter: centerPoint)
    tableView.addSubview(snapshot!)
    
    UIView.animateWithDuration(0.25, animations: { () -> Void in
      centerPoint.y = location.y
      cell.alpha = CellAlpha.Hidden.rawValue
      self.configureLocalSnapshot(centerPoint, transform: CGAffineTransformMakeScale(1.05, 1.05), alpha: 0.98)
    })
  }
  
  private func displaceCellAnimation(tableView: UITableView, indexPath: NSIndexPath) {
    tableView.moveRowAtIndexPath(sourceIndexPath!, toIndexPath: indexPath)
    sourceIndexPath = indexPath
    hideCell(tableView, indexPath: indexPath)
  }
  
  private func depositCellAnimation(tableView: UITableView, indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    cell.alpha = CellAlpha.Hidden.rawValue
    UIView.animateWithDuration(0.25, animations: { () -> Void in
      self.configureLocalSnapshot(cell.center, transform: CGAffineTransformIdentity, alpha: 0.0)
      cell.alpha = CellAlpha.Visible.rawValue
      
      }, completion: { (finished) in
        self.sourceIndexPath = nil
        self.snapshot?.removeFromSuperview()
        self.snapshot = nil;
    })
  }
  
  private func customSnapshotFromView(inputView: UIView, snapshotCenter: CGPoint) -> UIView {
    let image = takeCellSnapshot(inputView)
    
    let imageView = createViewFromImage(image)
    imageView.alpha = CellAlpha.Hidden.rawValue
    imageView.center = snapshotCenter
    
    return imageView
  }
  
  private func takeCellSnapshot(inputView: UIView) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
    inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  }
  
  private func createViewFromImage(image: UIImage) -> UIImageView {
    let imageView =  UIImageView(image: image)
    imageView.layer.masksToBounds = false
    imageView.layer.cornerRadius = 0.0
    imageView.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
    imageView.layer.shadowRadius = 5.0
    imageView.layer.shadowOpacity = 0.4
    
    return imageView
  }
  
  private func configureLocalSnapshot(center: CGPoint, transform: CGAffineTransform, alpha: CGFloat) {
    self.snapshot?.center = center
    self.snapshot?.transform = transform
    self.snapshot?.alpha = alpha
  }
}
