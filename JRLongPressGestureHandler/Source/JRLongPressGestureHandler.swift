import UIKit

public protocol JRLongPressGestureHandlerDelegate: class {
  func didEndLongPress(_ startIndexPath: IndexPath, endIndexPath: IndexPath)
}

open class JRLongPressGestureHandler {
  
  enum CellAlpha: CGFloat {
    case hidden = 0.0
    case visible = 1.0
  }
  
  fileprivate weak var delegate: JRLongPressGestureHandlerDelegate?
  fileprivate var snapshot: UIView?
  fileprivate var sourceIndexPath: IndexPath?
  fileprivate var previousIndexPath: IndexPath?
  fileprivate var backupIndexPath: IndexPath?
  fileprivate var startIndexPath: IndexPath!
  
  open var transformOnCellSelection: CGAffineTransform!
  open var transformOnCellDeposit: CGAffineTransform!
  open var durationForSelectionAnimation: TimeInterval!
  open var durationForDepositAnimation: TimeInterval!
  open var alphaForCell: CGFloat!
  
  public init(delegate: JRLongPressGestureHandlerDelegate) {
    self.delegate = delegate
    
    transformOnCellSelection = CGAffineTransform(scaleX: 1.05, y: 1.05)
    transformOnCellDeposit = CGAffineTransform.identity
    durationForSelectionAnimation = 0.25
    durationForDepositAnimation = 0.25
    alphaForCell = 0.98
  }
  
  open func longPressGestureRecognized(_ tableView: UITableView, gesture: UILongPressGestureRecognizer) {
    let gestureState: UIGestureRecognizerState = gesture.state
    let location: CGPoint = gesture.location(in: tableView)
    var indexPath: IndexPath? = tableView.indexPathForRow(at: location)
    
    if cellIsOutOfBounds(indexPath) {
      indexPath = self.backupIndexPath
    } else if cellWasOutOfBounds(tableView.numberOfRows(inSection: 0), indexPath: indexPath!) {
      self.backupIndexPath = indexPath
    }
    
    switch (gestureState) {
    case UIGestureRecognizerState.began:
      sourceIndexPath = indexPath
      startIndexPath = sourceIndexPath
      pickupCellAnimation(tableView, indexPath: indexPath!, location: location)
      
    case UIGestureRecognizerState.changed:
      var center: CGPoint = snapshot!.center
      center.y = location.y
      snapshot?.center = center
      
      if cellMoved(sourceIndexPath!, indexPath: indexPath!) {
        displaceCellAnimation(tableView, indexPath: indexPath!)
      }
      
      self.previousIndexPath = indexPath
      
    default:
      delegate!.didEndLongPress(startIndexPath, endIndexPath: indexPath!)
      depositCellAnimation(tableView, indexPath: indexPath!)

      break
    }
  }
  
  fileprivate func cellIsOutOfBounds(_ indexPath: IndexPath?) -> Bool {
    return indexPath == nil && backupIndexPath != nil
  }
  
  fileprivate func cellWasOutOfBounds(_ tableSize: Int, indexPath: IndexPath) -> Bool {
    return ((indexPath as NSIndexPath).row == 0 || (indexPath as NSIndexPath).row == tableSize - 1)
  }
  
  fileprivate func cellMoved(_ sourceIndexPath: IndexPath, indexPath: IndexPath) -> Bool {
    return indexPath != sourceIndexPath
  }
  
  fileprivate func hideCell(_ tableView: UITableView, indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)!
    cell.alpha = CellAlpha.hidden.rawValue
  }
  
  fileprivate func pickupCellAnimation(_ tableView: UITableView, indexPath: IndexPath, location: CGPoint) {
    let cell = tableView.cellForRow(at: indexPath)!
    var centerPoint = cell.center
    snapshot = customSnapshotFromView(cell, snapshotCenter: centerPoint)
    tableView.addSubview(snapshot!)
    
    UIView.animate(withDuration: durationForSelectionAnimation, animations: { () -> Void in
      centerPoint.y = location.y
      cell.alpha = CellAlpha.hidden.rawValue
      self.configureLocalSnapshot(centerPoint, transform: self.transformOnCellSelection, alpha: self.alphaForCell)
    })
  }
  
  fileprivate func displaceCellAnimation(_ tableView: UITableView, indexPath: IndexPath) {
    tableView.moveRow(at: sourceIndexPath!, to: indexPath)
    sourceIndexPath = indexPath
    hideCell(tableView, indexPath: indexPath)
  }
  
  fileprivate func depositCellAnimation(_ tableView: UITableView, indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)!
    cell.alpha = CellAlpha.hidden.rawValue
    UIView.animate(withDuration: durationForDepositAnimation, animations: { () -> Void in
      self.configureLocalSnapshot(cell.center, transform: self.transformOnCellDeposit, alpha: 0.0)
      cell.alpha = CellAlpha.visible.rawValue
      
      }, completion: { (finished) in
        self.sourceIndexPath = nil
        self.snapshot?.removeFromSuperview()
        self.snapshot = nil;
    })
  }
  
  fileprivate func customSnapshotFromView(_ inputView: UIView, snapshotCenter: CGPoint) -> UIView {
    let image = takeCellSnapshot(inputView)
    
    let imageView = createViewFromImage(image)
    imageView.alpha = CellAlpha.hidden.rawValue
    imageView.center = snapshotCenter
    
    return imageView
  }
  
  fileprivate func takeCellSnapshot(_ inputView: UIView) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
    inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image!
  }
  
  fileprivate func createViewFromImage(_ image: UIImage) -> UIImageView {
    let imageView =  UIImageView(image: image)
    imageView.layer.masksToBounds = false
    imageView.layer.cornerRadius = 0.0
    imageView.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
    imageView.layer.shadowRadius = 5.0
    imageView.layer.shadowOpacity = 0.4
    
    return imageView
  }
  
  fileprivate func configureLocalSnapshot(_ center: CGPoint, transform: CGAffineTransform, alpha: CGFloat) {
    self.snapshot?.center = center
    self.snapshot?.transform = transform
    self.snapshot?.alpha = alpha
  }
}
