//
//  WalletView.swift
//  Mochimo App
//
//  Created by User on 03/09/21.
//

import SwiftUI
import BottomSheet
import MobileCoreServices
import CryptoKit

struct WalletListView: View {
    @ObservedObject var wallet_manager = WalletListManager.singleton
    var body: some View {
        NavigationView {
            List {
                ForEach(WalletListManager.singleton.wallet_list, id: \.creation_id) { wallet in
                    NavigationLink(destination: SecureWalletView(id: wallet.creation_id)) {
                        HStack {
                            Image("wallet-icon")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(wallet.uiColor)
                            VStack {
                                Text(wallet.wallet_name)
                                    .bold()
                                Spacer()
                            }
                            Spacer()
                            /*
                            Image(systemName: "chevron.right")
                                .font(.title2)*/
                        }
                    }
                    .frame(height: 60)
                }
                .onDelete { indexSet in
                    wallet_manager.confirmWalletDeletion = true
                    wallet_manager.confirmWalletDeletionID = indexSet.first ?? 0
                        //self.listItems.remove(atOffsets: indexSet)
                    }
            }
            .navigationTitle("Your Wallets")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Settings") {
                        print("About tapped!")
                    }
                    Link("Help", destination: URL(string: "https://www.apple.com")!)
                }
            }
            .navigationBarItems(trailing:
                Button(action: {
                    print("Create Wallet Button clicked")
                    if(wallet_manager.show_bottom_sheet==false){
                        ViewManager.singleton.bottomsheet_screen = "create_wallet"
                        wallet_manager.show_bottom_sheet=true
                        wallet_manager.bottom_sheet_height = Int(UIScreen.main.bounds.size.height - 200)
                    }
                }) {
                    Image(systemName: "plus.rectangle.fill")
                        .resizable()
                        //.imageScale(.large)
                        .frame(width: 40, height: 24)
                }
                .padding(.trailing, 10)
            )
            
            .onAppear() {
                wallet_manager.balanceCheck_id = 1000
            }
            
        }
        .bottomSheet(isPresented: $wallet_manager.show_bottom_sheet, height: CGFloat(wallet_manager.bottom_sheet_height) , content: {
                        BottomSheetView()
            
        })
        .actionSheet(isPresented: $wallet_manager.confirmWalletDeletion) {
            ActionSheet(title: Text("WARNING: YOU ARE GOING TO DELETE A WALLET"), message: Text("Are you sure you want to delete " + wallet_manager.getSortedName() + "?"), buttons: [
                .destructive(Text("DELETE " + wallet_manager.getSortedName())) {
                                print("delete a wallet")
                },
                .cancel()
            ])
        }
        .navigationViewStyle(StackNavigationViewStyle())

    }

}

class WalletListManager: ObservableObject {
    static var singleton = WalletListManager()
    @Published var show_bottom_sheet = false
    @Published var bottom_sheet_height = 200
    
    @Published var confirmWalletDeletion = false
    @Published var confirmWalletDeletionID = 0
    
    @Published var wallet_list: [WalletData] = [WalletData]()
    @Published var open_wallet: WalletData? = nil
    
    var latest_block_num: UInt = 0
    var last_check_task = 0
    var apn_token = "" //Token for the APN
    
    let balanceCheck_task = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: true) { timer in
        if((Int(Date().timeIntervalSince1970) - WalletListManager.singleton.last_check_task) > 15) {
            WalletListManager.singleton.last_check_task = Int(Date().timeIntervalSince1970)
            WalletListManager.wotsBalanceChecker()
        }
    }
    var balanceCheck_busy = false
    var balanceCheck_id = 1000 //default id for blank screen
    
    init() {
        print("initio")
        
        UIApplication.shared.registerForRemoteNotifications()
        //just to reset
        //wallet_list = [WalletData]()
        //self.saveWalletsOfflineMode()
    }
    func getWalletsOfflineMode() {
        print("loading wallets from UserDefaults..")
        if let data = UserDefaults.standard.data(forKey: "wallets") {
            do {
                let decoder = JSONDecoder()
                let wallets = try decoder.decode([WalletData].self, from: data)
                wallet_list = wallets
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }
    }
    func saveWalletsOfflineMode() {
        let encoded_wallets = try! JSONEncoder().encode(wallet_list)
        UserDefaults.standard.set(encoded_wallets, forKey: "wallets")
        print("successfully saved wallet data to memory!")
    }
    func getSortedList() -> [WalletData] {
        wallet_list.sorted { (lhs:WalletData, rhs:WalletData) in
            return lhs.creation_id < rhs.creation_id
        }
    }
    func getSortedName() -> String {
        return getSortedList()[confirmWalletDeletionID].wallet_name
    }
    func getWalletFromId(id: Int) -> WalletData? {
        for wallet in wallet_list {
            if(wallet.creation_id == id) {
                return wallet
            }
        }
        return nil
    }
    @objc static func wotsBalanceChecker() {
        let shared = WalletListManager.singleton
        if(shared.balanceCheck_busy == true) {return}
        shared.balanceCheck_busy = true
        let targetId = shared.balanceCheck_id
        print("controllo balance")
        var wallet_check = shared.wallet_list.first(where: {$0.creation_id == targetId})
        //var wallet_check = shared.open_wallet
        guard let wallet_check = wallet_check else {
            print("not valid wallet")
            shared.balanceCheck_busy = false; return
        }
        DispatchQueue.global().async {
            for balance in wallet_check.balances {
                //RECOVER TEST
                //balance.balance_hash = wallet_check.mnemonic_hash
                //let test_balance_seed = sha256_hex(data: Data((wallet_check.mnemonic_hash + "0").data(using: .ascii)!) as NSData)
                //balance.balance_hash = test_balance_seed
                //balance.many_spent = 0
                //let wots_seed = sha256_hex(data: Data((balance.balance_hash + String(0)).data(using: .ascii)!) as NSData)
                //balance.wots_address = WotsClass().generateKeyPairFrom(wots_seed: wots_seed, tag: balance.tag)
                //print(balance.wots_address.toHexString())
                //shared.saveWalletsOfflineMode()
                //RECOVEr TEST
                let group = DispatchGroup()
                print("")
                group.enter()
                QueryManager.balanceAmount(wots: balance.wots_address, group: group) {success, nmcm in
                    print("got answ")
                    if(success == true) {
                        print("the wots address is registered ", nmcm!)
                        let pseudo_amount: Int = Int(nmcm!)
                        switch(balance.status) {
                        case 0: //address is still funding
                            if(pseudo_amount > 500) {
                                balance.status = 1
                                balance.blockStatus = shared.latest_block_num
                                balance.amount_nmcm = pseudo_amount
                            }
                            break
                        case 1:
                            balance.blockStatus = shared.latest_block_num
                            balance.amount_nmcm = pseudo_amount
                            break
                        case 2:
                            print("balance is funded to destination address")
                            print("the balance is recovered!")
                            if(pseudo_amount > 500 && pseudo_amount == balance.amount_nmcm) {
                                balance.status = 1
                                balance.blockStatus = shared.latest_block_num
                                //balance.amount_nmcm = pseudo_amount
                            }
                        case 10:
                            print("the balance tag has been funded!")
                            if(pseudo_amount > 500) {
                                balance.status = 1
                                balance.blockStatus = shared.latest_block_num
                                balance.amount_nmcm = pseudo_amount
                            }
                        case 11:
                            print("the balance is recovered from status 11!")
                            if(pseudo_amount > 500) {
                                print("successfully")
                                balance.status = 1
                                balance.blockStatus = shared.latest_block_num
                                balance.amount_nmcm = pseudo_amount
                            }
                        case 12:
                            print("the balance is recovered!")
                            if(pseudo_amount > 500) {
                                print("successfully")
                                balance.status = 1
                                balance.blockStatus = shared.latest_block_num
                                balance.amount_nmcm = pseudo_amount
                            }
                        default:
                            break
                        }
                        shared.saveWalletsOfflineMode()
                        //balance.amount_nmcm = Int(nmcm!)
                            //wallet_check.balances[wallet_check.balances.firstIndex(where: {$0.id == balance.id})!].amount_nmcm = 220
                        //balance.amount_nmcm = 2005
                            //balance.amount_nmcm = 200
                    } else {
                        print("balance doesn't exist ")
                        if(balance.status == 0 && (shared.latest_block_num - balance.blockStatus) > 3) {
                            print("the balance did not got fund")
                            balance.status = 10
                            balance.blockStatus = shared.latest_block_num
                        }
                        if(balance.status == 1 && (Int(shared.latest_block_num) - Int(balance.blockStatus)) > 2) {
                            print("the vanished for some reason")
                            balance.status = 11
                            balance.blockStatus = shared.latest_block_num
                        }
                        if(balance.status == 2 && (shared.latest_block_num - balance.blockStatus) > 2 && balance.blockStatus != 0) {
                            print("the transaction did not work properly", shared.latest_block_num, balance.blockStatus)
                            balance.status = 12
                            balance.blockStatus = shared.latest_block_num
                            shared.saveWalletsOfflineMode()
                        }
                        if((balance.status == 12 || balance.status == 11) && (shared.latest_block_num - balance.blockStatus) > 2) {
                            //Better approach: resolve the tag and check 2 wots past and 3 wots further
                            print("balance status", balance.status)
                            let stop_group = DispatchGroup()
                            stop_group.enter()
                            var wots_tag_owner = [UInt8]()
                            QueryManager.resolveTag(tag: balance.tag.hexaBytes, group: stop_group) {success, awots_tag_owner in
                                if(success == false) {
                                    print("ERROR: THE INDICATED TAG IS NOT BINDED TO ANY WOTS")
                                    return
                                }
                                wots_tag_owner = awots_tag_owner ?? [UInt8]()
                            }
                            stop_group.wait()
                            for n in (balance.many_spent - 1)...(balance.many_spent+3) {
                                DispatchQueue.global().async {
                                    let wots_seed = sha256_hex(data: Data((balance.balance_hash + String(n)).data(using: .ascii)!) as NSData)
                                    let change_address = WotsClass().generateKeyPairFrom(wots_seed: wots_seed, tag: balance.tag)
                                    if(change_address == wots_tag_owner) {
                                        balance.wots_address = change_address
                                        balance.many_spent = n
                                        balance.blockStatus = shared.latest_block_num
                                        balance.status = 2
                                        print("ROLL BACK BALANCE SUCCESS", balance.tag)
                                        shared.saveWalletsOfflineMode()
                                    }
                                }
                            }
                            
                        }
                    }
                }
                group.wait()
            }
            shared.balanceCheck_busy = false
        }
        
        //end of the task
        //shared.balanceCheck_busy = false
    }
}

struct WalletListView_Previews: PreviewProvider {
    static var previews: some View {
        MnemonicWordsPrintView(wallet_name: "adsf", mnemonic_words: "slipper rough swanky lunchmeat border prosecution bright steep arrogant cruise wicked another word also")
        
    }
}

struct BottomSheetView: View {
    @ObservedObject var view_manager: ViewManager = ViewManager.singleton
    var body: some View {
        if(view_manager.bottomsheet_screen == "create_wallet") {
            CreateWalletView()
        }
    }
}

struct CreateWalletView: View {
    @State var wallet_name = ""
    @State var password = ""
    @State var rpassword = ""
    @State var mnemonic_passphrase = RandomWords().generateRandom(80)
    
    @State var open = false
    @State var show_alert = false
    @State var alert_text = ""
    
    enum Field: Hashable {
            case usernameField
            case passwordField
            case passwordRepeatField
        }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Create Wallet")
                    .font(.title)
                    .bold()
                    .padding(.leading, 13)
                    .foregroundColor(.accentColor)
                Text("")
                    .frame(maxWidth: .infinity)
            }
            Group {
                Text("Wallet Name")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                TextField("Wallet name", text: $wallet_name)
                    .padding(.all)
                    .background(Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0))
                    .cornerRadius(3.0)
                    .padding(.horizontal)
                    .foregroundColor(.black)

                
                Text("Wallet Password")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 3)
                SecureField("Password", text: $password)
                    .padding(.all)
                    .background(Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0))
                    .cornerRadius(3.0)
                    .padding(.horizontal)
                    .foregroundColor(.black)

                Text("Wallet Password confirmation")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 3)
                SecureField("Repeat password", text: $rpassword)
                    .onChange(of: rpassword, perform: { value in
                        print(value)
                    })
                    .padding(.all)
                    .background(Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0))
                    .cornerRadius(3.0)
                    .padding(.horizontal)
                    .foregroundColor(.black)
            }
            //Now there are the mnemonic words
            Text("Mnemonic phrase (press to copy)")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 13)
            
            WithPopover(showPopover: $open,popoverSize: CGSize(width: 230, height: 80),
                content: {
                    Text(mnemonic_passphrase)
                    .frame(maxWidth: .infinity)
                    .padding(.all, 10)
                    .multilineTextAlignment(.center)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .padding(.horizontal, 10)
                    .onLongPressGesture {
                        UIPasteboard.general.string = mnemonic_passphrase
                        self.open.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            self.open = false
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    },
                    popoverContent: {
                        VStack {
                            Text("mnemonic passphrase copied to clipboard")
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                                .padding(.all)
                        }
                    })
            Button(action: {
                print("create wallet button clicked")
                //Check if the password correspond
                if(wallet_name == "") {
                    print("passwords don't correspond")
                    alert_text = "Please put a wallet name"
                    show_alert = true
                    return
                }
                if(password == "") {
                    print("passwords don't correspond")
                    alert_text = "Password cannot be null!"
                    show_alert = true
                    return
                }
                if(password != rpassword) {
                    print("passwords don't correspond")
                    alert_text = "The two password don't match!"
                    show_alert = true
                    return
                }
                MnemonicWordsPrintView(wallet_name: wallet_name, mnemonic_words: mnemonic_passphrase).printView()
                
                //now we should cereate the wallet object
                let iter_wallets = UserDefaults.standard.integer(forKey: "iter_wallets")
                let new_wallet = WalletData(creation_id: iter_wallets , wallet_name: wallet_name, mnemonic_hash: mnemonic_passphrase.sha256(), many_balances: 0, password_hash: password.sha256(), balances: [Balance](), gift_cards: [GiftCard](), settings: SingleWalletSettings())
                print(new_wallet)
                UserDefaults.standard.setValue(iter_wallets+1, forKey: "iter_wallets")
                WalletListManager.singleton.wallet_list.append(new_wallet)
                WalletListManager.singleton.saveWalletsOfflineMode()
                WalletListManager.singleton.show_bottom_sheet = false
                wallet_name = ""
                password = ""
                rpassword = ""
                mnemonic_passphrase = RandomWords().generateRandom(80)
                open = false
                show_alert = false
                alert_text = ""
                
            }) {
                Text("CREATE WALLET")
                    .foregroundColor(.white)
                    .bold()
                    .frame(width: 200 , height: 50, alignment: .center)
            }
            .cornerRadius(5)
            .background(Color.blue)
            .cornerRadius(5)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 15)
            
            Text("TIP: Make sure that you saved correctly the mnemonic phrase!")
                .padding(.all)
            
            Text("")
                .alert(isPresented: $show_alert) {
                    Alert(title: Text("Warning"), message: Text(alert_text), dismissButton: .default(Text("Go back")))
                        }
        }
    }
}

class WalletData: Encodable, Decodable {
    internal init(creation_id: Int, wallet_name: String, mnemonic_hash: String, many_balances: Int, password_hash: String, balances: [Balance], gift_cards: [GiftCard], settings: SingleWalletSettings, red: CGFloat = .random(in: 0...1), green: CGFloat = .random(in: 0...1), blue: CGFloat = .random(in: 0...1), alpha: CGFloat = 1.0) {
        self.creation_id = creation_id
        self.wallet_name = wallet_name
        self.mnemonic_hash = mnemonic_hash
        self.many_balances = many_balances
        self.password_hash = password_hash
        self.balances = balances
        self.gift_cards = gift_cards
        self.settings = settings
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    
    var creation_id: Int
    var wallet_name: String
    var mnemonic_hash: String
    var many_balances: Int
    var password_hash: String
    var balances: [Balance]
    var gift_cards: [GiftCard]
    var red: CGFloat = .random(in: 0...1), green: CGFloat = .random(in: 0...1), blue: CGFloat = .random(in: 0...1), alpha: CGFloat = 1.0
    var settings: SingleWalletSettings
    var uiColor: Color {
            return Color(UIColor(red: red, green: green, blue: blue, alpha: alpha))
        }
    
    enum CodingKeys: String, CodingKey {
        case creation_id = "creation_id"
        case wallet_name = "wallet_name"
        case mnemonic_hash = "mnemonic_hash"
        case many_balances = "many_balances"
        case password_hash = "password_hash"
        case balances = "balances"
        case gift_cards = "gift_cards"
        case settings = "settings"
        case red = "red"
        case green = "green"
        case blue = "blue"

    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.creation_id = try values.decodeIfPresent(Int.self, forKey: .creation_id)!
        self.wallet_name = try values.decodeIfPresent(String.self, forKey: .wallet_name) ?? "No Name"
        self.mnemonic_hash = try values.decodeIfPresent(String.self, forKey: .mnemonic_hash)!
        self.many_balances = try values.decodeIfPresent(Int.self, forKey: .many_balances) ?? 0
        self.password_hash = try values.decodeIfPresent(String.self, forKey: .password_hash)!
        self.balances = try values.decodeIfPresent([Balance].self, forKey: .balances) ?? [Balance]()
        self.gift_cards = try values.decodeIfPresent([GiftCard].self, forKey: .gift_cards) ?? [GiftCard]()
        self.settings = try values.decodeIfPresent(SingleWalletSettings.self, forKey: .settings) ?? SingleWalletSettings()
        self.red = try values.decodeIfPresent(CGFloat.self, forKey: .red) ?? .random(in: 0...1)
        self.green = try values.decodeIfPresent(CGFloat.self, forKey: .green) ?? .random(in: 0...1)
        self.blue = try values.decodeIfPresent(CGFloat.self, forKey: .blue) ?? .random(in: 0...1)
    }
}
class Balance: Encodable, Decodable, Hashable {
    static func == (lhs: Balance, rhs: Balance) -> Bool {
        if(lhs.id == rhs.id) {
            return true
        } else {
            return false
        }
    }
    func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
            hasher.combine(self.balance_hash)
        }
    var uuid = UUID()
    var id: Int
    var balance_hash: String
    var tag: String
    var wots_address: [UInt8]
    var amount_nmcm: Int = 0
    var status: Int
    var blockStatus: UInt
    var many_spent: Int
    /* status:
     0: the balance is being tagged
     1: the balance is ready for operations
     2: the balance is sending a transaction
     
     10: the tag process did not went well after 4 blocks
     11: the mcm vanished from state 1 without reasons
     12: the mcm aren't in the new wots after 4 blocks
     */
    
    init(id: Int, balance_hash: String, tag: String, wots_address: [UInt8], amount_nmcm: Int? = 0, status: Int, blockStatus: UInt? = nil, many_spent: Int? = nil) {
        self.id = id
        self.balance_hash = balance_hash
        self.tag = tag
        self.wots_address = wots_address
        self.status = status
        if(amount_nmcm != nil ) {
            self.amount_nmcm = amount_nmcm!
        } else {
            self.amount_nmcm = 0
        }
        if(blockStatus == nil) {
            self.blockStatus = WalletListManager.singleton.latest_block_num
        } else {
            self.blockStatus = blockStatus!
        }
        self.many_spent = many_spent ?? 0
    }
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case balance_hash = "balance_hash"
        case tag = "tag"
        case wots_address = "wots_address"
        case status = "status"
        case amount_nmcm = "amount_nmcm"
        case blockStatus = "blockStatus"
        case many_spent = "many_spent"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(Int.self, forKey: .id)!
        self.balance_hash = try values.decodeIfPresent(String.self, forKey: .balance_hash)!
        self.tag = try values.decodeIfPresent(String.self, forKey: .tag)!
        self.wots_address = try values.decodeIfPresent(Array<UInt8>.self, forKey: .wots_address)!
        self.status = try values.decodeIfPresent(Int.self, forKey: .status) ?? 2
        self.amount_nmcm = try values.decodeIfPresent(Int.self, forKey: .amount_nmcm) ?? 0
        self.blockStatus = try values.decodeIfPresent(UInt.self, forKey: .blockStatus) ?? 0
        self.many_spent = try values.decodeIfPresent(Int.self, forKey: .many_spent) ?? 0
    }
}

class GiftCard: Codable, Hashable {
    static func == (lhs: GiftCard, rhs: GiftCard) -> Bool {
        if(lhs.uuid == rhs.uuid) {
            return true
        } else {
            return false
        }
    }
    func hash(into hasher: inout Hasher) {
            hasher.combine(self.uuid)
            hasher.combine(self.status)
            hasher.combine(self.amount_nmcm)
        }
    var uuid = UUID()
    var amount_nmcm: Int = 0
    /* 0=filling, 1=available, 2=spent, to be deleted*/
    var status: Int
    var gift_seed: String
    var wots: [UInt8]
    
    init(amount_nmcm: Int, status: Int = 0, gift_seed: String, wots: [UInt8]? = nil) {
        self.amount_nmcm = amount_nmcm
        self.status = status
        self.gift_seed = gift_seed
        self.wots = wots ?? WotsClass().generateKeyPairFrom(wots_seed: gift_seed)
    }
    enum CodingKeys: String, CodingKey {
        case amount_nmcm = "amount_nmcm"
        case status = "status"
        case gift_seed = "gift_seed"
        case wots = "wots"
    }
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.amount_nmcm = try values.decodeIfPresent(Int.self, forKey: .amount_nmcm) ?? 0
        self.status = try values.decodeIfPresent(Int.self, forKey: .status) ?? 0
        self.gift_seed = try values.decodeIfPresent(String.self, forKey: .gift_seed)!
        self.wots = try values.decodeIfPresent([UInt8].self, forKey: .wots) ?? WotsClass().generateKeyPairFrom(wots_seed: try values.decodeIfPresent(String.self, forKey: .gift_seed)!)
    }
}

class SingleWalletSettings: Codable, Hashable {
    static func == (lhs: SingleWalletSettings, rhs: SingleWalletSettings) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    func hash(into hasher: inout Hasher) {
        //hasher.combine(self.uuid)
        hasher.combine(self.many_send_tx_nodes)
        hasher.combine(self.allow_biometrics)
    }
    var uuid = UUID()
    var many_send_tx_nodes: Int
    var many_resolve_nodes: Int
    var many_resolve_quorum: Int
    var many_balance_nodes: Int
    var many_balance_quorum: Int
    var allow_biometrics: Bool = false
    var allow_notifications: Bool = true
    
    init() {
        self.many_send_tx_nodes = 5
        self.many_resolve_nodes = 5
        self.many_resolve_quorum = 3
        self.many_balance_nodes = 5
        self.many_balance_quorum = 3
    }
    enum CodingKeys: String, CodingKey {
        case many_send_tx_nodes = "many_send_tx_nodes"
        case allow_biometrics = "allow_biometrics"
        case many_resolve_nodes = "many_resolve_nodes"
        case many_resolve_quorum = "many_resolve_quorum"
        case many_balance_nodes = "many_balance_nodes"
        case many_balance_quorum = "many_balance_quorum"
        case allow_notifications = "allow_notifications"
    }
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.many_send_tx_nodes = try values.decodeIfPresent(Int.self, forKey: .many_send_tx_nodes) ?? 5
        self.many_resolve_nodes = try values.decodeIfPresent(Int.self, forKey: .many_resolve_nodes) ?? 3
        self.many_resolve_quorum = try values.decodeIfPresent(Int.self, forKey: .many_resolve_quorum) ?? 3
        self.many_balance_nodes = try values.decodeIfPresent(Int.self, forKey: .many_balance_nodes) ?? 5
        self.many_balance_quorum = try values.decodeIfPresent(Int.self, forKey: .many_balance_quorum) ?? 3
        self.allow_biometrics = try values.decodeIfPresent(Bool.self, forKey: .allow_biometrics) ?? false
        self.allow_notifications = try values.decodeIfPresent(Bool.self, forKey: .allow_notifications) ?? true

    }
}
/*
struct MnemonicWordsPrintView: View {
    @State var wallet_name: String
    @State var mnemonic_words: String
    var body: some View {
        VStack {
            HStack {
                Text("Mochimo Mobile Wallet")
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 10)
                Image("mcm-logo-thin-black-scaleable")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100)
                Spacer()
            }
            .padding(.all)
            .rotation3DEffect(
                Angle(degrees: 30),
                axis: (x: -0.2, y: 1.0, z: -0.0)
            )
            Text("Recovery sheet \nKeep it dry. Keep it secured.")
                .multilineTextAlignment(.center)
            HStack {
                Text("Wallet name: " + wallet_name)
                Spacer()
            }
            .padding([.top, .horizontal])
            HStack {
                Text("created on " + MnemonicWordsPrintView.getCurrentDatetime())
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                Text("Mobile wallet version: v0.1")
                Spacer()
            }
            .padding(.horizontal)
            HStack {
                Text("Mnemonic words (use as recovery):")
                Spacer()
            }
            .padding(.horizontal)
            Text(mnemonic_words)
                .padding(.all)
                .border(Color.black, width: 2)
                .padding(.all)
                .lineSpacing(20)
                .font(Font.headline.weight(.semibold))
            Spacer()
        }
        .frame(maxWidth: 400, maxHeight: 400*1.4142)
        .foregroundColor(.black)
    }
    func printView() {
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = UIPrintInfo.OutputType.general
        printInfo.jobName = "My Print Job"

        // Set up print controller
        printController.printInfo = printInfo
        //UISimpleTextPrintFormatter(text: <#T##String#>)
        // Assign a UIImage version of my UIView as a printing iten
        printController.printingItem = self.snapshot()
        printController.present(animated: true, completionHandler: nil)
        // Do it
        //printController.presentFromRect(self.frame, inView: self, animated: true, completionHandler: nil)

    }
    static func getCurrentDatetime() -> String {
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        return df.string(from: Date())
    }
}
*/
struct MnemonicWordsPrintView: View {
    @State var wallet_name: String
    @State var mnemonic_words: String
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Mochimo")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Mobile")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Wallet")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 45))
                Image("mcm-logo-thin-black-scaleable")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 130, alignment: .center)
                    .padding(.top)
            }
            .padding(.all)
            Text("Mnemonic words sheet,")
                .font(.system(size: 20))
            Text("Keep it secured")
                .font(.system(size: 20))
            Text(mnemonic_words)
                .font(.system(size: 22))
                .padding(.horizontal, 5)
                .lineSpacing(20)
                .maxWidth(.infinity)
                .multilineTextAlignment(.center)
                .height(150)
                .border(Color.black, width: 2, cornerRadius: 5)
                .padding(.all)
            HStack {
                Text("Informations")
                    .font(.system(size: 20))
                    .padding(.leading)
                Spacer()
            }
            Text("Wallet name: " + wallet_name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading])
                .padding(.top, 5)
            Text("Created on: " + MnemonicWordsPrintView.getCurrentDatetime())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
            Text("Mobile Wallet version: MochiMobile v0.1")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
            Text("Mochimo Mobile Wallet Recovery Sheet")
                .padding(.all)
            Spacer()
        }
        .frame(maxWidth: 400, maxHeight: 400*1.4142)
        .foregroundColor(.black)

    }
    func printView() {
        DispatchQueue.main.async {
            let printController = UIPrintInteractionController.shared
            
            let printInfo = UIPrintInfo(dictionary:nil)
            printInfo.outputType = UIPrintInfo.OutputType.general
            printInfo.jobName = "My Print Job"

            // Set up print controller
            printController.printInfo = printInfo
            //UISimpleTextPrintFormatter(text: <#T##String#>)
            // Assign a UIImage version of my UIView as a printing iten
            printController.printingItem = self.snapshot()
            printController.present(animated: true, completionHandler: nil)
        }
        
        // Do it
        //printController.presentFromRect(self.frame, inView: self, animated: true, completionHandler: nil)

    }
    static func getCurrentDatetime() -> String {
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        return df.string(from: Date())
    }
}
