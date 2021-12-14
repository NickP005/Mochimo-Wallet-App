import Foundation
import NIO
import NIOCore
import CryptoSwift

enum TCPClientError: Error {
    case invalidHost
    case invalidPort
}


class NodeTCPHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    private var numBytes = 0
    var node_instance: Node?
    var status = 0
    var received_cache: [UInt8] = [UInt8]()
    
    init(node: Node?) {
        self.node_instance = node
    }
    // Channel connected
    func channelActive(context: ChannelHandlerContext) {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        
        print("Connected successfully to " + (context.remoteAddress?.ipAddress ?? "UNKNOWN IP"), df.string(from: d))
        node_instance!.sendOP(OP_HELLO)
        context.fireChannelActive()
    }
    //Channel disconnected
    func channelInactive(context: ChannelHandlerContext) {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        
        print("Disconnected from " + (context.remoteAddress?.ipAddress ?? "UNKNOWN"), df.string(from: d) )
        //context.fireChannelInactive()
        node_instance!.connected = false
        node_instance = nil
        context.close(promise: nil)
        //TESTTTTT
        //QueryManagerData.shared.connectedNodes = [Node]()
        //context.fireChannelInactive()
    }
    //Received a message
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        //print("Received data from " + (context.remoteAddress?.ipAddress ?? "UNKNOWN") + " ", buffer.readableBytes)
        let readableBytes: Int = buffer.readableBytes
        
        if let recv = buffer.readBytes(length: readableBytes) {
            received_cache.append(contentsOf: recv)
        }
        context.fireChannelRead(data)
    }
    func channelReadComplete(context: ChannelHandlerContext) {
        if(received_cache.count == 8920 ) {
            //print("Received complete packet from " + (context.remoteAddress?.ipAddress ?? "UNKNOWN"), received_cache.count )
            node_instance!.decodeIncomingMessage(full_response: received_cache)
            received_cache = [UInt8]()
            if(status == 1) {
                //print("closing cause status==1")
                /*
                node_instance!.connected = false
                context.close(promise: nil)
                node_instance = nil*/
                context.fireChannelInactive()
            }
            status = status + 1
            
        } else  if(received_cache.count == 0) {
            //print("probably the node wants to abort the connection..")
            //what should I do here?
        }
        
    }
    //Error is thrown by the socket instance
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}
class Node {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    weak var channel: Channel?
    var host: String?
    var port: Int
    var connected = false
    var task: NodeRequest
    
    var Transaction = TX()
    
    //var fulfilled_request: [NodeRequest] = [NodeRequest]()
    
    init(ip: String, port: Int?, node_request: NodeRequest) {
        self.host = ip
        self.port = port ?? 2095
        self.task = node_request
    }
    deinit {
        //self.group = nil

            //channel?.close()
        /*
        if(channel != nil) {
            try! channel?.closeFuture.wait()
            channel?.pipeline.close(promise: nil)
            channel = nil
            print("trying to shut down going")
            disconnect()
        }*/
        channel = nil
        group.shutdownGracefully() {error in
            
        }
        //print("deinit of Node", self.host!)
    }
    
    func isConnected() -> Bool {
        let status = channel?.isActive
        if(status == true ) {
            return true
        } else {
            channel = nil
            return false
        }
    }
    
    func connect(/*completion: @escaping (Channel) -> ()*/) throws {
        //227 120
        //print(withUnsafeBytes(of: UInt16(57893).bigEndian, Array.init))
        //print(UInt16(57893))
        if isConnected() {return}
        guard let host = host else {
            print("ERROR: Invalid IP/host")
            throw TCPClientError.invalidHost
        }
        
        bootstrap.connect(host: host, port: port).whenComplete() {[weak self] result in
            switch result {
            case .success(let channell):
                self?.channel = channell
                //print("connected!")
                self?.connected = true
                //completion(channell)
            case .failure(let error):
                print("failed to connect to " + error.localizedDescription)
                self?.connected = false
            }

        }
        print("closefuture")
        try channel?.closeFuture.wait() //<-- Whats the purpose of this??
        //channel?.pipeline.close(promise: nil)
        //try group.syncShutdownGracefully()
    }
    func disconnect() {
        do {
            print("trying to shut down")
            try group.syncShutdownGracefully()
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        self.connected = false
        //print("Successfully disconnected from " + (channel?.remoteAddress?.ipAddress ?? "UNKNOWN_ADDR"))
    }
    private var bootstrap: ClientBootstrap {
        return ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer {[weak self] channel in //[weak self]
                channel.pipeline.addHandler(NodeTCPHandler(node: self))
        }
    }
    func sendTagResolve(tag: [UInt8]) {
        //print("going to resolve tag ", tag)
        
        //OP_RESOLVE
        // send at dst_addr the tag
        Transaction.dst_addr = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2196)
        Transaction.dst_addr.append(contentsOf: tag)
        //print("lenght of", Transaction.dst_addr.count)
        //print(Transaction.dst_addr)
        sendOP(OP_RESOLVE)
    }
    func sendBalance(wots: [UInt8]) {
        //OP_BALANCE
        Transaction.src_addr = wots
        //print("lenght of bal", Transaction.src_addr.count)
        sendOP(OP_BALANCE)
    }
    func sendTransaction(payload: [UInt8]) {
        Transaction.src_addr = Array(payload[0...(2208 - 1)])
        Transaction.dst_addr = Array(payload[2208...(4416 - 1)])
        Transaction.chg_addr = Array(payload[4416...(6624 - 1)])
        Transaction.send_total = Array(payload[6624...(6632 - 1)])
        Transaction.change_total = Array(payload[6632...(6640 - 1)])
        Transaction.tx_fee = Array(payload[6640...(6648 - 1)])
        Transaction.tx_sig = Array(payload[6648...(8792 - 1)])
        print("sending OP_TX")
        sendOP(OP_TX)
    }
    func sendOP(_ op_code: Int) {
        Transaction.opcode = withUnsafeBytes(of: UInt16(op_code).littleEndian, Array.init)
        //print(Transaction.opcode)
        guard let channel = channel else {
            print("channel not set. cannot send OP")
            return
        }
        print("sending OP",op_code, " to ", channel.remoteAddress?.ipAddress ?? "UNKNOWN", "...")
        Transaction.computeFullArray()
        let data = Data(bytes: Transaction.full_array, count: 8920)
        
        var buffer = channel.allocator.buffer(capacity: 8920)
        buffer.writeBytes(data.bytes)
        channel.write(buffer, promise: nil)
        channel.flush()
        //print(buffer.readBytes(length: buffer.readableBytes) ?? "idk")
        
        /*
        var result = ""
        for nn in Transaction.full_array {
            result += "0x"
            result = result + String(format:"%02X", nn)
            result += " "
        }
        print(result)*/
        
    }
    func decodeIncomingMessage(full_response: [UInt8]/*, completion: (Bool)->()*/) {
        //Check length is correct
        //print(full_response)
        if(full_response.count != 8920) {
            print("Mochimo protocol violation: remote ", channel?.remoteAddress?.ipAddress ?? "UNKNOWN",
                  " sent an invalid packet lenght")
            print(full_response.count)
            //completion(true)
        }
        if(full_response[2...3] != [57,5] || full_response[8918...8919] != [205, 171]) {
            print("Mochimo protocol violation: remote ", channel?.remoteAddress?.ipAddress ?? "UNKNOWN",
                  " sent an invalid packet. Network or trailer are incorrect/unsupported")
            print(full_response[8918...8919])
        }
        if(Array(full_response[8916...8917]) != withUnsafeBytes(of: crc16().crc16Ccitt(data: Array(full_response[0...8915]), seed: 0x0, final: 0), Array.init)) {
            print("Mochimo protocol violation: remote ", channel?.remoteAddress?.ipAddress ?? "UNKNOWN",
                  " sent an invalid packet. CRC16 incorrect")
        }
        //Now we need to check if the id2 is correct
        if(Transaction.id2 != [0,0] && Transaction.id2 != Array(full_response[6...7])) {
            print("Mochimo protocol violation: remote ", channel?.remoteAddress?.ipAddress ?? "UNKNOWN",
                  " sent an invalid packet. The ID is not consistent")
        }
        Transaction.id2 = Array(full_response[6...7])
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        //print("Received a correct packet via TCP", df.string(from: Date()))
        
        //Now copy the block data into our local TX (it doesn't really matters if it is correct or not
        // The important thing is that the node will accept our following requests
        
        //print("weight", Transaction.cblock)
        let opcode = Array(full_response[8...9]).ull_to_bytes(2).toUInt()
        switch opcode {
        case 2:
            print("Successfully received an HELLO_ACK packet from", channel!.remoteAddress!.ipAddress!)
            //completion(false)
            Transaction.cblock = Array(full_response[10...17])
            Transaction.blocknum = Array(full_response[18...25])
            Transaction.cblockhash = Array(full_response[26...57])
            Transaction.pblockhash = Array(full_response[58...89])
            Transaction.weight = Array(full_response[90...121])
            doNextRequestedTask()
        case 13:
            print("Successfully received an OP_SEND_BAL packet from", channel!.remoteAddress!.ipAddress!)
            let send_total = Array(full_response[6748...6755]) //balance amount
            let change_total = Array(full_response[6756...6763]) //if was found
            let cblock_num = Transaction.cblock.ull_to_bytes(8).toUInt()
            let shared = QueryManagerData.shared
            
            var balance_found = false
            let balance_total = send_total.ull_to_bytes(8).toUInt()
            //print("balance total", balance_total)
            if(balance_total != 0) {
                balance_found = true
            }
            
            
            //var backup = [NodeAnswer]()
            DispatchQueue.main.sync {
                if(!shared.answer_pool.keys.contains(task)) {
                    return
                }
                shared.answer_pool[task]?.append(NodeAnswer(requestType: .resolveTag, ip: channel?.remoteAddress?.ipAddress ?? "UNKNOWN", ask1: task.data1, data0: balance_found, data1: send_total, block_num: cblock_num))
            }
            
            
        case 14:
            print("Successfully received an OP_RESOLVE packet from", channel!.remoteAddress!.ipAddress!)
            let send_total = Array(full_response[6748...6755])
            let dst_addr = Array(full_response[2332...4539])
            let block_num = Transaction.blocknum.ull_to_bytes(8).toUInt()
            let shared = QueryManagerData.shared
            
            var tag_found = false
            if(send_total == [0,0,0,0,0,0,0,0]) {
                print("tag address not found")
            } else {
                //print("send total", send_total)
                tag_found = true
            }
            /*
            if(shared.answer_pool[task] == nil) {
                shared.answer_pool[task] = [NodeAnswer]()
            }*/
            DispatchQueue.main.sync {
                if(!shared.answer_pool.keys.contains(task)) {
                    return
                }
                shared.answer_pool[task]!.append(NodeAnswer(requestType: .resolveTag, ip: channel?.remoteAddress?.ipAddress ?? "UNKNOWN", ask1: task.data1, data0: tag_found, data1: dst_addr, block_num: block_num))
            }
            
            //The node will close the connection anyway..
            if(channel?.isActive == true) {
                print("closing connection from OP_RESOLVE")
                //DispatchQueue.global().async {
                //    try! self.channel!.closeFuture.wait()
                //}
                //completion(true)
                //channel?.close(promise: nil)
                //ctx.close(promise: nil)
                //disconnect()
            }
            //completion(true)
            //print(full_response)
        default:
            print("ERROR: Received an unknown OPCODE", opcode, " from ", channel!.remoteAddress!.ipAddress!)
        }
                //Here will ask new tasks to do
        //doNextRequestedTask()
    }
    
    /// Will check on the main "to-do" if there is any request that needs to be done
    func doNextRequestedTask() {
        //this will avoid that when the timer goes the instance will be already closed
        if(connected==false) {return}
        //print("going next task")
        switch task.requestType {
        case .resolveTag:
            //print("Doing a resolve tag task")
            sendTagResolve(tag: task.data1)
            break
        case .balance:
            //print("Doing a balance task")
            sendBalance(wots: task.data1)
            break
        case .sendTX:
            sendTransaction(payload: task.data1)
            break
        default:
            break
            //print("no next task")
        }
        
    }
}

class TX {
    var full_array: [UInt8]
    
    
    let version: [UInt8] //2 bytes
    let network: [UInt8] //2 bytes
    let id1: [UInt8] //2 bytes
    var id2: [UInt8] //2 bytes
    var opcode: [UInt8] //2 bytes
    var cblock: [UInt8] //8 bytes
    var blocknum: [UInt8] //8 bytes --> default is all 0 (BigInt(0))
    var cblockhash: [UInt8]
    var pblockhash: [UInt8]
    var weight: [UInt8]
    var len: [UInt8]
    
    //ONLY IN CASE OF OPCODE TX
    //THIS PART WILL BE CHANGED IN MOCHIMO 2.0
    var src_addr: [UInt8] //2208 bytes
    var dst_addr: [UInt8] //2208 bytes
    var chg_addr: [UInt8] //2208 bytes
    var send_total: [UInt8] //8 bytes
    var change_total: [UInt8] //8 bytes
    var tx_fee: [UInt8] //8 bytes
    var tx_sig: [UInt8] //2144 bytes
    
    var crc_16: [UInt8] //2 bytes
    let trailer: [UInt8] //2 bytes

    
    init() {
        // set the default values
        version = [4, 2] //pVersion changes every hard fork,
                         //currently 4. Cbits is 2 to indicate we are a C_wallet
        network = [57, 5]
        id1 = withUnsafeBytes(of: Int.random(in: 0 ... Int.max ), Array.init).ull_to_bytes(2)
            //This is the random generated ID by this side
        id2 = [UInt8](repeating: 0, count: 2) //This is the random generated ID by the other node
        opcode = withUnsafeBytes(of: OP_NULL.bigEndian, Array.init).ull_to_bytes(2)
        cblock = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(8)
        blocknum = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(8)
        cblockhash = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(32)
        pblockhash = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(32)
        weight = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(32)
        len = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2)
        /* transaction buffer */
        src_addr = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2208)
        dst_addr = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2208)
        chg_addr = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2208)
        send_total = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(8)
        change_total = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(8)
        tx_fee = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(8)
        tx_sig = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2144)
        /* end of trasaction buffer */
        crc_16 = withUnsafeBytes(of: 0.bigEndian, Array.init).ull_to_bytes(2)
        trailer = [205, 171]
        
        full_array = [UInt8]()
        //computeFullArray()
        
        //junk things
        //print(full_array)
    }
    
    func computeFullArray() {
        full_array = [UInt8]()
        full_array.append(contentsOf: version)
        full_array.append(contentsOf: network)
        full_array.append(contentsOf: id1)
        full_array.append(contentsOf: id2)
        full_array.append(contentsOf: opcode)
        full_array.append(contentsOf: cblock)
        full_array.append(contentsOf: blocknum)
        full_array.append(contentsOf: cblockhash)
        full_array.append(contentsOf: pblockhash)
        full_array.append(contentsOf: weight)
        full_array.append(contentsOf: len)
        full_array.append(contentsOf: src_addr)
        full_array.append(contentsOf: dst_addr)
        full_array.append(contentsOf: chg_addr)
        full_array.append(contentsOf: send_total)
        full_array.append(contentsOf: change_total)
        full_array.append(contentsOf: tx_fee)
        full_array.append(contentsOf: tx_sig)
        //print("full array lenght", full_array.count)
        //crc_16 = withUnsafeBytes(of: CryptoSwift.Checksum.crc16(full_array).bigEndian, Array.init).ull_to_bytes(2)
        crc_16 = withUnsafeBytes(of: crc16().crc16Ccitt(data: full_array, seed: 0x0, final: 0), Array.init)
        //let crc_arc = crc16().crc16(full_array, type: .ARC)
        //let crc_MODBUS = crc16().crc16(full_array, type: .MODBUS)
        //let arcStr = String(format: "%4X\n", crc_arc?.bigEndian as! CVarArg)
        //let modbusStr = String(format: "%4X\n", crc_MODBUS?.littleEndian as! CVarArg)

        //print("CRCs: ARC = " + arcStr + " MODBUS = " + modbusStr)
        //print("crc16()", String(format: "%4X", crc16().crc16Ccitt(data: full_array, seed: 0x0, final: 0)))
        //print("cryptoswift: ", String(format: "%4X", CryptoSwift.Checksum.crc16(full_array)))
        
        full_array.append(contentsOf:  crc_16)
        full_array.append(contentsOf: trailer)
        
        //print("crc16")
        //print(crc_16)
        //print(full_array.count)
    }
    
}
