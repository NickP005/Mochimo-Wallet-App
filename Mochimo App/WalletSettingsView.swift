//
//  WalletSettingsView.swift
//  Mochimo App
//
//  Created by User on 02/10/21.
//

import SwiftUI
import Combine
struct WalletSettingsView: View {
    @State var settings: SingleWalletSettings
    @State var many_nodes_resolve: String = ""
    @State var many_quorum_resolve: String = ""
    @State var many_nodes_balance = ""
    @State var many_quorum_balance = ""
    @State var many_nodes_tx = ""
    @State var biometrics = false
    @State var notifications = false
    var body: some View {
        VStack(spacing: 1) {
            Form {
                Toggle(isOn: $biometrics) {
                    Text("Allow biometrics")
                }
                .onReceive(Just(biometrics)) { new_value in
                    if(settings.allow_biometrics != new_value) {
                        settings.allow_biometrics = new_value
                        WalletListManager.singleton.saveWalletsOfflineMode()
                    }
                }
                
                Toggle(isOn: $notifications) {
                    Text("Allow notifications (balance update)")
                }
                .onReceive(Just(notifications)) { new_value in
                    if(settings.allow_notifications != new_value) {
                        settings.allow_notifications = new_value
                        WalletListManager.singleton.saveWalletsOfflineMode()
                    }
                }
                Section(header: Text("resolve tag")) {
                    HStack {
                        Text("n. of requests")
                            .frame(width: 110, alignment: .leading)
                        Divider()
                        TextField("requests for OP_RESOLVE", text: $many_nodes_resolve)
                            .keyboardType(.numberPad)
                            .onReceive(Just(many_nodes_resolve)) { new_value in
                                var filtered = Int(new_value.filter { "0123456789".contains($0) }) ?? 5
                                if(many_nodes_resolve == "") {
                                    return
                                }
                                if(filtered > 9) {
                                    filtered = 9
                                } else if(filtered < 2) {
                                    filtered = 2
                                }
                                if(settings.many_resolve_nodes != filtered) {
                                    settings.many_resolve_nodes = filtered
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                }
                                self.many_nodes_resolve = String(filtered)
                            }
                            .frame(maxWidth: .infinity)
                    }
                    HStack {
                        Text("quorum")
                            .frame(width: 110, alignment: .leading)
                        Divider()
                        TextField("quorum for OP_RESOLVE", text: $many_quorum_resolve)
                            .keyboardType(.numberPad)
                            .onReceive(Just(many_quorum_resolve)) { new_value in
                                var filtered = Int(new_value.filter { "0123456789".contains($0) }) ?? 3
                                if(many_quorum_resolve == "") {
                                    return
                                }
                                if(filtered > 9) {
                                    filtered = 9
                                } else if(filtered < 2) {
                                    filtered = 2
                                }
                                if(filtered > Int(many_nodes_resolve) ?? settings.many_resolve_nodes) {
                                    filtered = Int(many_nodes_resolve) ?? settings.many_resolve_nodes
                                }
                                if(settings.many_resolve_quorum != filtered) {
                                    settings.many_resolve_quorum = filtered
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                }
                                self.many_quorum_resolve = String(filtered)
                            }
                    }
                    
                }
                
                Section(header: Text("get balance")) {
                    HStack {
                        Text("n. of requests")
                            .frame(width: 110, alignment: .leading)
                        Divider()
                        TextField("requests for OP_BALANCE", text: $many_nodes_balance)
                            .keyboardType(.numberPad)
                            .onReceive(Just(many_nodes_balance)) { new_value in
                                var filtered = Int(new_value.filter { "0123456789".contains($0) }) ?? 5
                                if(many_nodes_balance == "") {
                                    return
                                }
                                if(filtered > 9) {
                                    filtered = 9
                                } else if(filtered < 2) {
                                    filtered = 2
                                }
                                if(settings.many_balance_nodes != filtered) {
                                    settings.many_balance_nodes = filtered
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                }
                                self.many_nodes_balance = String(filtered)
                            }
                            .frame(maxWidth: .infinity)
                    }
                    HStack {
                        Text("quorum")
                            .frame(width: 110, alignment: .leading)
                        Divider()
                        TextField("quorum for OP_BALANCE", text: $many_quorum_balance)
                            .keyboardType(.numberPad)
                            .onReceive(Just(many_quorum_balance)) { new_value in
                                var filtered = Int(new_value.filter { "0123456789".contains($0) }) ?? 3
                                if(new_value == "") {
                                    return
                                }
                                if(filtered > 9) {
                                    filtered = 9
                                } else if(filtered < 2) {
                                    filtered = 2
                                }
                                if(filtered > Int(many_nodes_resolve) ?? settings.many_resolve_nodes) {
                                    filtered = Int(many_nodes_resolve) ?? settings.many_resolve_nodes
                                }
                                if(settings.many_balance_quorum != filtered) {
                                    settings.many_balance_quorum = filtered
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                }
                                self.many_quorum_balance = String(filtered)
                            }
                    }
                    
                }
                Section(header: Text("push transaction")) {
                    HStack {
                        Text("n. of requests")
                            .frame(width: 110, alignment: .leading)
                        Divider()
                        TextField("requests for OP_TX", text: $many_nodes_tx)
                            .keyboardType(.numberPad)
                            .onReceive(Just(many_nodes_tx)) { new_value in
                                var filtered = Int(new_value.filter { "0123456789".contains($0) }) ?? 5
                                if(new_value == "") {
                                    return
                                }
                                if(filtered > 9) {
                                    filtered = 9
                                } else if(filtered < 2) {
                                    filtered = 2
                                }
                                if(settings.many_send_tx_nodes != filtered) {
                                    settings.many_send_tx_nodes = filtered
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                }
                                self.many_nodes_tx = String(filtered)
                            }
                            .frame(maxWidth: .infinity)
                    }
                }
                Button(action: {
                    //let paths = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)
                    let wallet_data = WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == WalletListManager.singleton.balanceCheck_id})
                    let encoded_wallet = try! JSONEncoder().encode(wallet_data)
                    let av = UIActivityViewController(activityItems: [encoded_wallet.dataToFile(fileName: (wallet_data!.wallet_name + " - Mochimo Wallet File.mwf") )!], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                }) {
                    HStack {
                        Text("Export wallet")
                            .bold()
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                Button(action: {
                    settings.allow_biometrics = false
                    settings.allow_notifications = true
                    settings.many_balance_nodes = 5
                    settings.many_balance_quorum = 3
                    settings.many_resolve_quorum = 3
                    settings.many_resolve_nodes = 5
                    settings.many_send_tx_nodes = 5
                    WalletListManager.singleton.saveWalletsOfflineMode()
                    updateInputs()
                }) {
                    Text("RESET ALL SETTINGS")
                        .bold()
                        .foregroundColor(.red)
                }
            }
            .onAppear() {
                updateInputs()
            }
        }
    }
    func updateInputs() {
        many_nodes_resolve = String(settings.many_send_tx_nodes)
        many_quorum_resolve = String(settings.many_resolve_quorum)
        many_nodes_balance = String(settings.many_balance_nodes)
        many_quorum_balance = String(settings.many_balance_quorum)
        many_nodes_tx = String(settings.many_send_tx_nodes)
        biometrics = settings.allow_biometrics
        notifications = settings.allow_notifications
    }
}
/*
struct WalletSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        WalletSettingsView()
    }
}
*/
