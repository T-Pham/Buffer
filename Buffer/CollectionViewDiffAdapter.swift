//
//  Adapters.swift
//  Buffer
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if os(iOS)
  import UIKit

  public class CollectionViewDiffAdapter<ElementType: Equatable>:
  NSObject, AdapterType, UICollectionViewDataSource {

    public typealias Type = ElementType
    public typealias ViewType = UICollectionView

    public private(set) var buffer: Buffer<ElementType>

    public private(set) weak var view: ViewType?

    /// Right now this only works on a single section of a collectionView.
    /// If your collectionView has multiple sections, though, you can just use multiple
    /// CollectionViewDiffAdapter, one per section, and set this value appropriately on each one.
    public var sectionIndex: Int = 0

    public required init(buffer: BufferType, view: ViewType) {
      guard let buffer = buffer as? Buffer<ElementType> else {
        fatalError()
      }
      self.buffer = buffer
      self.view = view
      super.init()
      self.buffer.delegate = self
    }

    public required init(initialElements: [ElementType], view: ViewType) {
      self.buffer = Buffer(initialArray: initialElements)
      self.view = view
      super.init()
      self.buffer.delegate = self
    }

    private var indexPaths: (insertion: [NSIndexPath], deletion: [NSIndexPath]) = ([], [])

    private var cellForItemAtIndexPath: ((UICollectionView, ElementType, NSIndexPath)
      -> UICollectionViewCell)? = nil

    /// Returns the element currently on the front buffer at the given index path.
    public func displayedElementAtIndex(index: Int) -> Type {
      return self.buffer.currentElements[index]
    }

    /// The total number of elements currently displayed.
    public func countDisplayedElements() -> Int {
      return self.buffer.currentElements.count
    }

    /// Replace the elements buffer and compute the diffs.
    /// - parameter newValues: The new values.
    /// - parameter synchronous: Wether the filter, sorting and diff should be executed
    /// synchronously or not.
    /// - parameter completion: Code that will be executed once the buffer is updated.
    public func update(newValues: [ElementType]? = nil,
                       synchronous: Bool = false,
                       completion: ((Void) -> Void)? = nil) {
      self.buffer.update(newValues, synchronous: synchronous, completion: completion)
    }

    /// Configure the TableView to use this adapter as its DataSource.
    /// - parameter automaticDimension: If you wish to use 'UITableViewAutomaticDimension'
    /// as 'rowHeight'.
    /// - parameter estimatedHeight: The estimated average height for the cells.
    /// - parameter cellForRowAtIndexPath: The closure that returns a cell for the given
    /// index path.
    public func useAsDataSource(cellForItemAtIndexPath:
      (UICollectionView, ElementType, NSIndexPath) -> UICollectionViewCell) {
      self.view?.dataSource = self
      self.cellForItemAtIndexPath = cellForItemAtIndexPath
    }

    /// Tells the data source to return the number of rows in a given section of a table view.
    public func collectionView(collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
      return self.buffer.currentElements.count
    }

    /// Asks the data source for a cell to insert in a particular location of the table view.
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath
      indexPath: NSIndexPath) -> UICollectionViewCell {
      return self.cellForItemAtIndexPath!(collectionView,
                                          self.buffer.currentElements[indexPath.row],
                                          indexPath)
    }
  }

  extension CollectionViewDiffAdapter: BufferDelegate {

    /// Notifies the receiver that the content is about to change.
    public func bufferWillChangeContent(buffer: BufferType) {
      self.indexPaths = ([], [])
    }

    /// Notifies the receiver that rows were deleted.
    public func bufferDidDeleteElementAtIndices(buffer: BufferType, indices: [UInt]) {
      self.indexPaths.deletion = indices.map({
        NSIndexPath(forRow: Int($0), inSection: self.sectionIndex)
      })
    }

    /// Notifies the receiver that rows were inserted.
    public func bufferDidInsertElementsAtIndices(buffer: BufferType, indices: [UInt]) {
      self.indexPaths.insertion = indices.map({
        NSIndexPath(forRow: Int($0), inSection: self.sectionIndex)
      })
    }

    /// Notifies the receiver that the content updates has ended.
    public func bufferDidChangeContent(buffer: BufferType) {
      self.view?.performBatchUpdates({
        self.view?.insertItemsAtIndexPaths(self.indexPaths.insertion)
        self.view?.deleteItemsAtIndexPaths(self.indexPaths.deletion)
        }, completion: nil)
    }

    /// Called when one of the observed properties for this object changed.
    public func bufferDidChangeElementAtIndex(buffer: BufferType, index: UInt) {
      self.view?.reloadItemsAtIndexPaths(
        [NSIndexPath(forRow: Int(index), inSection: self.sectionIndex)])
    }

    /// Notifies the receiver that the content updates has ended and the whole array changed.
    public func bufferDidChangeAllContent(buffer: BufferType) {
      self.view?.reloadData()
    }
  }

#endif
