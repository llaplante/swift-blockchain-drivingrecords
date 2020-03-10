//
//  Models.swift
//  App
//
//  Created by Lance on 2/23/20.
//

import Foundation
import Vapor


protocol SmartContract {
    func apply(transaction: Transaction)
}

class TransactionTypeSmartContract: SmartContract {
    
    func apply(transaction: Transaction) {
        print("Applying SmartContract to transaction")
    }
    
}


enum TransactionType: String, Content {
    case domestic
    case international
}

final class Transaction : Content {
    
    var driverLicenseNumber :String
    var violationType :String
    var noOfVoilations :Int = 1
    var isDrivingLicenseSuspended :Bool = false
      
    init(licenseNoHash :String, violationType :String) {
        self.driverLicenseNumber = licenseNoHash
        self.violationType = violationType
    }
}

final class Block : Content {
    
    var index :Int = 0
    var previousHash : String = ""
    var hash :String!
    var nonce :Int
    var defaultTransactionKey: String
    
    private (set) var transactions :[Transaction] = [Transaction]()
    
    
    var key :String {
        get {
            if !transactions.isEmpty, let transactionData = try? JSONEncoder().encode(transactions) {
                if let transactionJSONString = String(data: transactionData, encoding: .utf8) {
                    return String(index) + previousHash + String(nonce) + transactionJSONString
                }
            }
            return String(index) + previousHash + String(nonce) + defaultTransactionKey
        }
    }
    
    init() {
        self.nonce = 0
        let l = 94500491000671.0
        defaultTransactionKey = String(NSDate().timeIntervalSince1970).replacingOccurrences(of: ".", with: "!") +
            String( Double.random(in: -l ... l)).replacingOccurrences(of: ".", with: "@")
    }
    
    func addTransaction(txn: Transaction) {
        transactions.append(txn)
    }
    
}

final class BlockChain : Content {
    
    private (set) var blocks :[Block] = [Block]()
    private (set) var nodes = [BlockchainNode]()
    private var drivingRecordSmartContract :DrivingRecordSmartContract = DrivingRecordSmartContract()
    private let useSmartContracts: Bool = true
    
    
    // Configure so that SmartContracts are not Context
    private enum CodingKeys : CodingKey {
        case useSmartContracts
        case blocks
        case nodes
        case drivingRecordSmartContract
    }
    
    init(genesisBlock: Block) {
        print("Initializing BlockChain with the genesis block ...")
        addBlock(genesisBlock)
    }
    
    func registerNodes(nodes :[BlockchainNode]) -> [BlockchainNode] {
        self.nodes.append(contentsOf: nodes)
        return self.nodes
    }
    
    func addBlock(_ block: Block) {
        
        // Get the previous hash for the block's key and then generate the block's Hash
        if blocks.isEmpty {
            block.previousHash = "00000000000000"
            block.hash = generateHash(for: block)
        }
        blocks.append(block)
        
    }
    
    func getNextBlock(transactions: [Transaction]) -> Block {
        
        let block = Block()
        transactions.forEach { transaction in
                  
            // applying smart contract BEFORE adding the transaction to the block and mining the block
            // Once a transaction is added and the block mined - IT IS IMMUTABLE ( so cannot apply smart contract )
            drivingRecordSmartContract.apply(transaction: transaction, allBlocks: self.blocks)
            block.addTransaction(txn: transaction)
            
        }
              
        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)
        
        return block
        
    }
    
    private func getPreviousBlock() -> Block {
        return blocks.last!
    }
    
    func generateHash(for block: Block) -> String {
        
        var hash = block.key.sha1Hash()
        while( !hash.hasPrefix("00") ) {
            block.nonce += 1
            hash = block.key.sha1Hash()
        }
        return hash
    }
    
    func transactionsBy(using drivingLicenseNumber :String) -> [Transaction] {
          
        var transactions = [Transaction]()
        let predicate = drivingLicenseNumber.sha1Hash()
        
        self.blocks.forEach { block in
              
              block.transactions.forEach { transaction in
                  
                  if transaction.driverLicenseNumber == predicate {
                      transactions.append(transaction)
                  }
              }
        }
          
        return transactions
          
    }
    
}


final class BlockchainNode :Content {
    
    var address :String
    
    init(address :String) {
        self.address = address
    }
    
}


// String Extension
extension String {
    
    func sha1Hash() -> String {
        
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}
