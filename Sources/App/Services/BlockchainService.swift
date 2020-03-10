//
//  BlockchainService.swift
//  App
//
//  Created by Lance on 2/23/20.
//

import Foundation

class BlockchainService {
    
    let ClosureWithinLoop = true
    
    private (set) var blockChain: BlockChain!
    
    init() {
        blockChain = BlockChain(genesisBlock: Block())
    }
    
    func getBlockChain() -> BlockChain {
        return blockChain
    }
    
    func getNextBlock( transactions: [Transaction]) -> Block {
        let block = blockChain.getNextBlock(transactions: transactions)
        blockChain.addBlock(block)
        return block
    }
    
    func getNodes() -> [BlockchainNode] {
           return blockChain.nodes
    }
       
    func registerNodes(nodes :[BlockchainNode]) -> [BlockchainNode] {
           return blockChain.registerNodes(nodes: nodes)
    }
    
      /*
          This function takes a closure argument which is escaped.
          This means that the closure will be executed independently of function completion e.g. returm
          So the closure might be invoked during function execution or after function completion. The URLSession
          task ( which invokes the closuer ) executes asynchronously independent of the function.
     
          The clousure takes a Blockchain argument and returns a void
          Although the closure is invoked multiple times within the node loop 
       */
    func resolve(completion : @escaping (BlockChain) -> ()) {
          
          let nodes = blockChain.nodes
          
          for node in nodes {
              
              let url = URL(string :"\(node.address)/api/blockchain")!
            
              print("resolve is getting data from node: \(url)")
              
              // Make sure that we remember to resume the URLSession task
              URLSession.shared.dataTask(with: url) { data, _, _ in
                  
                  if let data = data {
                      
                    let blockchain = try! JSONDecoder().decode(BlockChain.self, from: data)
                      
                      if self.blockChain.blocks.count < blockchain.blocks.count {
                          self.blockChain = blockchain
                      }
                    
                    if ( self.ClosureWithinLoop ) {
                       // Invoke the completion handler closure
                      print("resolve completion handler with block count: \(self.blockChain.blocks.count) for node: \(node.address)")
                      completion(self.blockChain)
                    }
    
                  }
                  
              }.resume()
              
          }
        
          if ( !self.ClosureWithinLoop ) {
            // Invoke the completion handler closure
            print("resolve completion handler with block count: \(self.blockChain.blocks.count)")
            completion(self.blockChain)
          }
        
      }
    
    
}
