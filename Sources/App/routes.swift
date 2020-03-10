import Vapor

/// Register your application's routes here.

/*
    By default you will access the routes paths uisng http://[host]:[port]/[route]
    E,g http://localhost:8080/hello
    NOTE: The default port is 8080. This can be modified when using the vapor commands to run the app.
          To do so:
            1. cd to the project directory
            2. Build the app e.f. 'vapor build'
            3. Start the app with the desired port e.g. 'vapor run --port=8090'
 */
public func routes(_ router: Router) throws {
  
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Create the controller
    let blockchainController = BlockchainController()
    
    // Define routes
    router.get("api/greet", use: blockchainController.greet)
    router.get("api/blockchain", use: blockchainController.getBlockchain)
    router.post(TransactionWrapper.self, at: "/api/mine", use: blockchainController.mine)
    router.post([BlockchainNode].self, at: "/api/nodes/register", use: blockchainController.registerNodes)
    router.get("/api/nodes", use: blockchainController.getNodes)
    router.get("api/resolve", use:blockchainController.resolve)
    router.get("api/driving-records", String.parameter, use: blockchainController.getDrivingRecords)
   
}
