import Foundation
import CoreData

/// Core Data managed object for Budget entity
///
/// This class will be extended by Core Data categories and custom extensions
@objc(Budget)
public class Budget: NSManagedObject {
    // This is the base class for the Budget entity
    // Core Data will extend this with properties via categories
    // Custom functionality is in Budget+Extensions.swift
}

