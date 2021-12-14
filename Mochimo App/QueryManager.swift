//
//  QueryManager.swift
//  Mochimo App
//
//  Created by User on 08/09/21.
//

import Foundation

class QueryManager {
    static func resolveTag(tag: [UInt8], group: DispatchGroup? = nil, completion: @escaping (Bool, [UInt8]?)->() ) {
        print("resolving tag")
        let start = DispatchTime.now()
        //First of all we have to create a node request
        let node_request = NodeRequest(requestType: .resolveTag, data1: tag)
        let shared = QueryManagerData.shared
        /*
        if(!shared.request_pool.contains(node_request)) {
            //doesn't already contain the request
            shared.request_pool.append(node_request)
            //QueryManager.updateConnectedNodes()
        }*/
        //print("already connected", shared.connectedNodes)
        QueryManagerData.shared.answer_pool[node_request] = [NodeAnswer]()
        
        let wallet_data = WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == WalletListManager.singleton.balanceCheck_id})
        let connect_needed = (wallet_data?.settings.many_resolve_quorum ?? 6) - 1
        QueryManager.connectAndSend(connect_needed, node_request)
        checkResolved(request: node_request) {node_answer in
            print("successfully got an answer for tag!")
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
            print("Time to evaluate problem: \(timeInterval) seconds")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                shared.request_pool.removeAll(where: {$0.uuid == node_request.uuid})
                //test
                DispatchQueue.main.sync {
                    shared.answer_pool.removeValue(forKey: node_request)
                }
            }
            guard let node_answer = node_answer else {
                completion(false, nil)
                if(group != nil) {
                    group?.leave()
                }
                return
            }
            //Here updates to the latest block num everything
            if(WalletListManager.singleton.latest_block_num != node_answer.block_num && node_answer.block_num != 0) {
                //updated the block num
                WalletListManager.singleton.latest_block_num = node_answer.block_num
            }
            completion(node_answer.data0, node_answer.data1)
            guard let group = group else {
                print("no group")
                return
            }
            group.leave()
        }
        
    }
    static func balanceAmount(wots: [UInt8],  group: DispatchGroup? = nil, completion: @escaping (Bool, UInt?)->() ) {
        print("resolving balance")
        let start = DispatchTime.now()
        //First of all we have to create a node request
        let node_request = NodeRequest(requestType: .balance, data1: wots)
        let shared = QueryManagerData.shared
        DispatchQueue.main.sync {
            QueryManagerData.shared.answer_pool[node_request] = [NodeAnswer]()
        }
        let wallet_data = WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == WalletListManager.singleton.balanceCheck_id})
        let connect_needed = (wallet_data?.settings.many_balance_nodes ?? 6) - 1
        QueryManager.connectAndSend(connect_needed, node_request)
        checkResolved(request: node_request) { node_answer in
            print("successfully got an answer for balance!")
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
            print("Time to evaluate balance: \(timeInterval) seconds")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                shared.request_pool.removeAll(where: {$0.uuid == node_request.uuid})
                //test
                DispatchQueue.main.sync {
                    shared.answer_pool.removeValue(forKey: node_request)
                }

            }
            guard let node_answer = node_answer else {
                completion(false, nil)
                if(group != nil) {
                    group?.leave()
                }
                return
            }
            //Here updates to the latest block num everything
            print("latest node num", node_answer.block_num )
            if(WalletListManager.singleton.latest_block_num != node_answer.block_num && node_answer.block_num != 0) {
                //updated the block num
                WalletListManager.singleton.latest_block_num = node_answer.block_num
            }
            completion(node_answer.data0, node_answer.data1.ull_to_bytes(8).toUInt())
            guard let group = group else {
                print("no group")
                return
            }
            group.leave()
        }
    }
    static func sendTransaction(from: [UInt8], to: [UInt8], change: [UInt8], amount: UInt, send: UInt, seed: String) {
        var payload = [UInt8]()
        payload.append(contentsOf: from)
        payload.append(contentsOf: to)
        payload.append(contentsOf: change)
        payload.append(contentsOf: withUnsafeBytes(of: UInt64(send).littleEndian, Array.init))
        payload.append(contentsOf: withUnsafeBytes(of: UInt64(amount - (send + 500)).littleEndian, Array.init))
        payload.append(contentsOf: withUnsafeBytes(of: UInt64(500).littleEndian, Array.init))
        print("payload to send", payload)
        let signature = WotsClass().generateSignatureFrom(wots_seed: seed, payload: payload)
        payload.append(contentsOf: signature)
        //Now will give this payload to the socket manager as a whole task
        print("payload size ", payload.count)
        let node_request = NodeRequest(requestType: .sendTX, data1: payload)
        let shared = QueryManagerData.shared
        let wallet_data = WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == WalletListManager.singleton.balanceCheck_id})
        let connect_needed = (wallet_data?.settings.many_send_tx_nodes ?? 6) - 1
        QueryManager.connectAndSend(connect_needed, node_request)
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            shared.request_pool.removeAll(where: {$0.uuid == node_request.uuid})
        }
    }
    static func checkResolved(request: NodeRequest, iter: Int = 0, found: @escaping (NodeAnswer?)->()) {
        let shared = QueryManagerData.shared
        //var nodes_ips = [String]()
        var answers = [[UInt8]: [String]]()
        
        let groul = DispatchGroup()
        groul.enter()
        var to_iter: [NodeAnswer] = [NodeAnswer]()
        DispatchQueue.main.sync {
            to_iter = shared.answer_pool[request] ?? [NodeAnswer]()
            groul.leave()
        }
        groul.wait()
        
        to_iter.forEach() {item in
            if(answers[item.data1] == nil) {
                answers[item.data1] = [String]()
            }
            answers[item.data1]?.append(item.ip)
        }
        var answ_comp = [[UInt8]:Int]()
        var win_answ: [UInt8]? = nil
        for (key, ips) in answers {
            answ_comp[key] = ips.count
        }

        if(answ_comp.count != 0) {
            for (key, value) in answ_comp {
                if (win_answ != nil) {
                    if(value > answ_comp[win_answ!]!) {
                        win_answ = key
                    }
                } else {
                    win_answ = key
                }
            }
            var quorum_need = 3
            let wallet_data = WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == WalletListManager.singleton.balanceCheck_id})
            if(request.requestType == .resolveTag) {
                quorum_need = (wallet_data?.settings.many_resolve_quorum ?? 3) - 1
            } else if(request.requestType == .balance) {
                quorum_need = (wallet_data?.settings.many_balance_quorum ?? 3) - 1
            }
            if(answ_comp[win_answ!]! > quorum_need) {
                print("successfully got quorum", answ_comp[win_answ!]!)
                //print(answ_comp)
                //print(answers)
                var answ: NodeAnswer?
                let groul = DispatchGroup()
                var to_iter: [NodeAnswer] = [NodeAnswer]()
                groul.enter()
                DispatchQueue.global().sync {
                    to_iter = shared.answer_pool[request] ?? [NodeAnswer]()
                    groul.leave()
                }
                groul.wait()
                to_iter.forEach() {item in
                    if(item.data1 == win_answ) {
                        answ = item
                    }
                }
                found(answ!)
                return
            } else {
                //print("let's wait some more time to get quorum. Recursing again..")
            }
        }
        //print(shared.request_pool)
        let new_iter = iter + 1
        if(iter == 25) {
            QueryManager.connectAndSend(2, request)
        }
        if(iter == 32) {
            QueryManager.connectAndSend(1, request)
        }
        if(iter > 40) {
            print("TIMEOUT to check tag")
            found(nil)
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            checkResolved(request: request, iter: new_iter, found: found)
        }
    }
    static func connectAndSend(_ many_nodes: Int, _ node_request: NodeRequest) {
        let shared = QueryManagerData.shared
        shared.connectedNodes.removeAll(where: {$0.isConnected() == false})
        for _ in 0...many_nodes {
            var potential_ip = IP_NODES_LIST.randomElement()
            var keep = true
            var many_wrong = 0
            while(keep) {
                var gone_wrong = false
                shared.connectedNodes.forEach() {cnt_check in
                    if(cnt_check.host == potential_ip) {
                        potential_ip = IP_NODES_LIST.randomElement()
                        gone_wrong = true
                        many_wrong += 1
                        if(many_wrong == 5) {
                            shared.connectedNodes.removeAll(where: {$0.isConnected() == false})
                        }
                    }
                }
                if(gone_wrong == false) {
                    keep = false
                }
            }
            //DispatchQueue.global().async {
                let client = Node(ip: potential_ip!, port: 2095, node_request: node_request)
                try! client.connect()
                //DispatchQueue.main.async {
                    shared.connectedNodes.append(client)
                //}
            //}
        }
    }
    /*
    static func updateConnectedNodes() {
        let shared = QueryManagerData.shared
        
        //First of all check if the nodes in the array are connected or not
        shared.connectedNodes.removeAll(where: {$0.isConnected() == false})
        //print(shared.connectedNodes)
        //Now we have to compute how many remaining nodes there are
        let remaining_nodes = 0 - shared.connectedNodes.count
        if(remaining_nodes < 0) {return}
        for _ in 0...remaining_nodes {
            var potential_ip = IP_NODES_LIST.randomElement()
            var keep = true
            while(keep) {
                var gone_wrong = false
                shared.connectedNodes.forEach() {cnt_check in
                    if(cnt_check.host == potential_ip) {
                        potential_ip = IP_NODES_LIST.randomElement()
                        gone_wrong = true
                    }
                }
                if(gone_wrong == false) {
                    keep = false
                }
            }
            let client = Node(ip: potential_ip!, port: 2095)
            try! client.connect() {_ in }
            shared.connectedNodes.append(client)
        }
        
    }*/
}

class QueryManagerData: ObservableObject {
    static var shared = QueryManagerData()
    var connectedNodes: [Node] = [Node]()
    var request_pool: [NodeRequest] = [NodeRequest]()
    var answer_pool: [NodeRequest: [NodeAnswer]] = [NodeRequest: [NodeAnswer]]()
    
}

enum RequestNodeType {
    case null
    case resolveTag
    case balance
    case blockNum
    case sendTX
}

struct NodeRequest: Equatable, Hashable {
    let uuid = UUID()
    let requestType: RequestNodeType
    //var ip: String
    /* data1: resolveTag=Tag address, balance=wots full address, sendTX=whole TX byte section*/
    let data1: [UInt8]
    /* data2 */
}

struct NodeAnswer: Equatable, Hashable {
    let uuid = UUID()
    var requestType: RequestNodeType
    var ip: String
    /* ask1: resolveTag=Tag address, balance=wots full address*/
    var ask1: [UInt8]
    /* data0: resolveTag=false if not found, balance=false if invalid wots balance */
    var data0: Bool
    /* data1: resolveTag=tagged address, balance= balance of wots small endian*/
    var data1: [UInt8]
    
    var block_num: UInt
}
