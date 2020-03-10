//
//  BlockchainController.swift
//  App
//
//  Created by Lance on 2/22/20.
//

import Foundation
import Vapor

class BlockchainController {
    
    static let ExplicitType: Bool = true
    let Log: Bool = true
    let blockchainService = BlockchainService()
    
    func greet( req: Request ) -> Future<String> {

        return Future.map(on: req) { () -> String in
            return "Welcome to Blockchain"
        }
    }
    
    func log ( msg: String ) {
        if Log {
            print(msg)
        }
    }
    
    // Return the current blockchain
    func getBlockchain( req: Request ) -> BlockChain {
        return blockchainService.getBlockChain()
    }
    
    
    /*
        Extract the driver license number path parameter and query the blockchain for
        all transacrions that match
     */
    func getDrivingRecords( req: Request ) -> [Transaction] {
        let driverLicenseNumber = try! req.parameters.next(String.self)
        if let blockchain = blockchainService.blockChain {
            log(msg: "Finding driving records for license number: \(driverLicenseNumber)")
           return blockchain.transactionsBy(using: driverLicenseNumber)
        } else {
            return [Transaction]()
        }
    }
    
    
    /*
        Using the input transaction info add a new block to the chain
        NOTE: We receive a TransactionWrapper in JSON with clear text license number and create a Transaction
              using a hashed value
    */
    func mine( req: Request, transactionWrapper: TransactionWrapper) -> Block {
       
        let licenseNoHash = transactionWrapper.driverLicenseNumber.sha1Hash()
        let transaction = Transaction(licenseNoHash: licenseNoHash, violationType: transactionWrapper.violationType)
        return blockchainService.getNextBlock(transactions: [transaction])
        
    }
    
    // Input the list of nodes comprising the blockchain server set
    func registerNodes(req: Request, nodes: [BlockchainNode]) -> [BlockchainNode] {
        return blockchainService.registerNodes(nodes: nodes)
    }
    
    func getNodes(req: Request) -> [BlockchainNode] {
        return blockchainService.getNodes()
    }
    
    /*
        Resolve conflicts across the blockchain node set so that the longest chain will become the 'truth' chain
     
        NOTE: Please be aware that the Blockchain ( returned via the Future<Blockchain> ) will likley NOT match the
              final 'truth' blockchain. This is due to the asynchronous completion handlers which 'complete' the
              EventLoopPromise<Blockchain> promise. The first completion handler to complete will 'complete' the promise.
              This renders the promise immutable so that subsequent completions ( one of which may contain the 'truth' blockchain )
              will have no impact.
     
              Although the Blockchain response may be inaccurate the blockchain model itself will be updated correctly.
     
        NOTE: The approach below attempts to return the 'truth' blockchain by deferring the Promise until the last node reports.
              Definitely not robust enough to be production worthy ( it assumes that all nodes will respond!!! )
    */
    func resolve(req :Request) -> Future<BlockChain> {
           
        let nodeCount = blockchainService.getNodes().count
        var nodeResponseCount = 0
        
        self.log(msg: "BlockchainController.resolve - across node count: \(nodeCount)")
        
        let promise :EventLoopPromise<BlockChain> = req.eventLoop.newPromise()
        
        if ( BlockchainController.ExplicitType ) {
            
          blockchainService.resolve { blockchain in   // return argument is explicit
            nodeResponseCount += 1
            self.log(msg: "BlockchainController.resolve - completion block count: \(blockchain.blocks.count) for node #\(nodeResponseCount)")
            if nodeResponseCount >= nodeCount {
                promise.succeed(result: blockchain)
            }
            
          }
            
        } else {
        
          blockchainService.resolve {              // return argument is implicit
            nodeResponseCount += 1
            self.log(msg: "BlockchainController.resolve - completion block count: \($0.blocks.count) for node #\(nodeResponseCount)")
            if nodeResponseCount >= nodeCount {
                promise.succeed(result: $0)
            }
          }
            
        }
        
        let result = promise.futureResult
        log(msg: "Exit BlockchainController.resolve with result: \(result)")
        
        return result
    }
}

//MARK: - TransactionWrapper   Allows UI and JSON code/decode using clear text driver license number

final class TransactionWrapper : Content {
    var driverLicenseNumber :String
    var violationType :String
    init(licenseNo :String, violationType :String) {
          self.driverLicenseNumber = licenseNo
          self.violationType = violationType
    }
}
