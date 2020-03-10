//
//  SmartContracts.swift
//  App
//
//  Created by Lance on 3/3/20.
//

import Foundation
import Vapor

final class DrivingRecordSmartContract : Content {
    
    func apply(transaction :Transaction, allBlocks :[Block]) {
        
        allBlocks.forEach { block in
            
            block.transactions.forEach { trans in
                
                if trans.driverLicenseNumber == transaction.driverLicenseNumber {
                    transaction.noOfVoilations += 1
                    print("Updating number of violations to: \(transaction.noOfVoilations)")
                }
                
                if transaction.noOfVoilations > 5 {
                    print("Number of violations exceeds max - license set to suspended")
                    transaction.isDrivingLicenseSuspended = true
                }
                
            }
            
        }
        
    }
    
}
