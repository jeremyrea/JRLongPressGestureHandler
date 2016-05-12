//
//  JRGestureRecognizer.swift
//  Semper
//
//  Created by Jeremy Rea on 2016-05-11.
//  Copyright © 2016 Jeremy Rea. All rights reserved.
//

import UIKit

public protocol JRLongPressGestureHandlerDelegate: class {
  func updateDataSource(sourceRow: Int, destinationRow: Int)
  func savePosition(startRow: Int, endRow: Int)
}

public class JRLongPressGestureHandler {
  
  private weak var delegate: JRLongPressGestureHandlerDelegate?
  
  private var snapshot: UIView? = nil
  private var sourceIndexPath: NSIndexPath? = nil
  private var previousIndexPath: NSIndexPath? = nil
  private var backupIndexPath: NSIndexPath? = nil
  private var permuteIndex: Int!
  
  public init(delegate: JRLongPressGestureHandlerDelegate) {
    self.delegate = delegate
  }
  
  public func longPressGestureRecognized(tableView: UITableView, gesture: UILongPressGestureRecognizer) {
    let state: UIGestureRecognizerState = gesture.state;
    let location: CGPoint = gesture.locationInView(tableView)
    var indexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(location)
    
    // This prevents the snapshot from persisting on superview when the cell is let-go in nil indexPath
    if (indexPath == nil && backupIndexPath != nil) {
      indexPath = self.backupIndexPath
    } else if (indexPath!.row == 0 || indexPath?.row == tableView.numberOfRowsInSection(0) - 1) {
      self.backupIndexPath = indexPath
    }
    
    switch (state) {
    case UIGestureRecognizerState.Began:
      sourceIndexPath = indexPath
      permuteIndex = sourceIndexPath!.row
      
      let cell = tableView.cellForRowAtIndexPath(indexPath!)!
      snapshot = customSnapshotFromView(cell)
      
      var center = cell.center
      snapshot?.center = center
      snapshot?.alpha = 0.0
      tableView.addSubview(snapshot!)
      
      UIView.animateWithDuration(0.25, animations: { () -> Void in
        center.y = location.y
        self.snapshot?.center = center
        self.snapshot?.transform = CGAffineTransformMakeScale(1.05, 1.05)
        self.snapshot?.alpha = 0.98
        cell.alpha = 0.0
      })
      
    case UIGestureRecognizerState.Changed:
      var center: CGPoint = snapshot!.center
      center.y = location.y
      snapshot?.center = center
      
      // Scrolling
      //      if(indexPath!.row+1 >= tableView.indexPathsForVisibleRows()?.count) {
      //        tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
      //      }
      
      // Is destination valid and is it different from source?
      if (indexPath != sourceIndexPath) {
        // ... update data source.
        delegate!.updateDataSource(sourceIndexPath!.row, destinationRow: indexPath!.row)
        
        // ... move the rows.
        tableView.moveRowAtIndexPath(sourceIndexPath!, toIndexPath: indexPath!)
        
        // ... and update sourceIndex so it is in sync with UI changes.
        sourceIndexPath = indexPath
        
        // We want to keep the cell invisible so we don't see it beneath the snapshot
        let cell = tableView.cellForRowAtIndexPath(indexPath!)!
        cell.alpha = 0.0
      }
      
      self.previousIndexPath = indexPath
      
    default:
      // Save CoreData model
      delegate!.savePosition(permuteIndex, endRow: indexPath!.row)
      
      // Clean up.
      let cell = tableView.cellForRowAtIndexPath(indexPath!)!
      cell.alpha = 0.0
      UIView.animateWithDuration(0.25, animations: { () -> Void in
        self.snapshot?.center = cell.center
        self.snapshot?.transform = CGAffineTransformIdentity
        self.snapshot?.alpha = 0.0
        // Undo fade out.
        cell.alpha = 1.0
        
        }, completion: { (finished) in
          self.sourceIndexPath = nil
          self.snapshot?.removeFromSuperview()
          self.snapshot = nil;
      })
      break
    }
  }
  
  private func customSnapshotFromView(inputView: UIView) -> UIView {
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
    inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    
    // Create an image view.
    let snapshot = UIImageView(image: image)
    snapshot.layer.masksToBounds = false
    snapshot.layer.cornerRadius = 0.0
    snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
    snapshot.layer.shadowRadius = 5.0
    snapshot.layer.shadowOpacity = 0.4
    
    return snapshot
  }
}
