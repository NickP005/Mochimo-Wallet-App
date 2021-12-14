//
//  SecureWalletView.swift
//  Mochimo App
//
//  Created by User on 04/09/21.
//
import Foundation
import Combine
import SwiftUI
import SwiftUIX
import BottomSheet
import CodeScanner
import LocalAuthentication

struct SecureWalletView: View {
    //@ObservedObject var instance: SecureWalletManager
    @State var wallet_id: Int
    @StateObject var instance: SecureWalletManager
    
    init(id: Int) {
        self.wallet_id = id
        self._instance = StateObject( wrappedValue: SecureWalletManager(wallet_data: WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == id})!))
        //self.instance = SecureWalletManager(wallet_data: WalletListManager.singleton.getWalletFromId(id: id)!)
        //self.instance =  SecureWalletManager(wallet_data: WalletListManager.singleton.wallet_list.first(where: {$0.creation_id == id})!)
    }
    /*
    init(id: Int) {
        print("on init secure")
        self.wallet_id = id
        instance = SecureWalletManager(wallet_data: WalletListManager.singleton.getWalletFromId(id: id)!)
        //instance.isWalletLocked = true
        
    }*/
    var body: some View {
        
        if(instance.isWalletLocked) {
            SecureWalletPassowrdView(parent_view: self)
                .navigationBarTitle(instance.wallet_data.wallet_name)
                .onAppear() {
                    if(instance.wallet_data.settings.allow_biometrics) {
                        DispatchQueue.main.async {
                            authWithBiometrics()
                        }
                    }
                }
        } else {
            WalletMainView(instance: instance)
                //.navigationBarTitle("")
                .navigationBarTitleView(Text("").height(0), displayMode: .inline)
                .navigationBarItems(trailing:
                        NavigationLink(destination: WalletSettingsView(settings: instance.wallet_data.settings)) {
                        Image(systemName: "gearshape.fill")
                    }
                    .padding(.trailing, 10)
                )
            .maxWidth(.infinity)
            .maxHeight(.infinity)
            
            .onAppear() {
                //self.instance.bottom_sheet_add_balance = NewBalanceView(instance: self.instance)
                WalletListManager.singleton.balanceCheck_id = wallet_id
                WalletListManager.singleton.balanceCheck_task.fire()
                instance.do_update = true
            }
            .onDisappear(){
                //reload_view_task.invalidate()
                print("view disappear")
                instance.do_update = false
            }
            .bottomSheet(isPresented: $instance.addBalanceSheet, height: CGFloat(600) , content: {
                //NewBalanceView(instance: self.instance)
                //self.instance.bottom_sheet_add_balance
                if(instance.addBalanceSheet == true) {
                    NewBalanceView(instance: self.instance)
                }
            })
        }
    }
    func authWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "Unlock the wallet"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                DispatchQueue.main.async {
                    if success {
                        print("biometrics are correct")
                        instance.isWalletLocked = false
                        unlockedExecute()
                        // authenticated successfully
                    } else {
                        // there was a problem
                    }
                }
            }
        } else {
            print("no biometrics")
            // no biometrics
        }
    }
    func unlockedExecute() {
        let apn_token = WalletListManager.singleton.apn_token
        if(instance.wallet_data.settings.allow_notifications) {
            var tags = [String]()
            instance.wallet_data.balances.forEach() { balance in
                tags.append(balance.tag)
            }
            if(apn_token != "") {
                NotificationManager().updateTags(deviceToken: apn_token, tags: tags)
            } else {
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (allowed, error) in
                         //This callback does not trigger on main loop be careful
                        if allowed {
                          print("Allowed") //import os
                        } else {
                          print("Error")
                        }
                    }
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                    let apn_token2 = WalletListManager.singleton.apn_token
                    if(apn_token2 != "") {
                        NotificationManager().updateTags(deviceToken: apn_token2, tags: tags)
                    }
                }
            }
        }
    }
}

class SecureWalletManager: ObservableObject {
    @Published var isWalletLocked = true
    @Published var wallet_data: WalletData
    @Published var addBalanceSheet = false
    var bottom_sheet_add_balance: NewBalanceView?
    var balance_list: WalletMainView?
    @Published var update_touch = false
    @Published var do_update: Bool = true
    var timer: Timer = Timer()

    init(wallet_data: WalletData) {
        //WalletListManager.singleton.open_wallet = wallet_data
        self.wallet_data = wallet_data
        WalletListManager.singleton.open_wallet = self.wallet_data
        timer.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            if(self?.do_update == true) {
                self?.update_touch = !self!.update_touch
                //print("update touch")
            }
        }
        print("secure wallet resets")
    }
    deinit {
        print("secure wallet deinit")
        timer.invalidate()
        //WalletListManager.singleton.wallet_list[WalletListManager.singleton.wallet_list.firstIndex(where: {$0.creation_id == wallet_data.creation_id})!] =  wallet_data
        //wallet_data.balances[wallet_check.balances.firstIndex(where: {$0.id == balance.id})!].amount_nmcm = 220
       // WalletListManager.singleton.open_wallet = nil
    }
    func loadWalletData() {
        
    }
    func saveWalletData() {
        
    }
}
/*
struct SecureWalletView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceSlotView(bal_id: 0, tag: "0308d44db2e72058004a4143", status: 0, amount_nmcm: 0)
            .preferredColorScheme(.light)
            
    }
}*/

struct SecureWalletPassowrdView: View {
    var parent_view: SecureWalletView
    @State var password_field: String = ""
    @State var show_wrong_password = false
    
    var body: some View {
        VStack {
            Text("")
                .frame(height: 50)
            WithPopover(showPopover: $show_wrong_password ,popoverSize: CGSize(width: 250, height: 40),
                content: {
                    HStack(spacing: 0) {
                        Text("Password")
                            .padding(.all)
                            .frame(maxHeight: .infinity)
                            .border(Color.black.opacity(0.1), width: 0.4)
                        SecureField("wallet password", text: $password_field) {
                            print("Logging..")
                            //Check if the password is correct
                            let input_field_sha = password_field.sha256()
                            if(input_field_sha == parent_view.instance.wallet_data.password_hash) {
                                print("password is correct")
                                parent_view.instance.isWalletLocked = false
                                parent_view.unlockedExecute()
                            } else {
                                print("password is incorrect")
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                //UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                show_wrong_password = true
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.all)
                        .border(Color.black.opacity(0.1), width: 0.4)
                    }
                    .frame(height: 50)
                    },
                    popoverContent: {
                        VStack {
                            
                            Text("The password is incorrect")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.all)
                        }
                    })
            
            
            Spacer()
        }
        
    }
}



struct WalletMainView: View {
    @State var picker = ""
    @State var scanQR: Bool = false
    @State var open_send_link: Int? = 0
    @State var open_send_tag: String? = nil
    @State var statuses: [Int] = [Int]()
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 180))]
    @ObservedObject var wallet_manager_instance = WalletListManager.singleton
    @ObservedObject var instance: SecureWalletManager

    /*
    init(instance: SecureWalletManager) {
        self.instance = instance
        //print("instance init")

        
    }*/
    //@Binding var parent_view: SecureWalletView
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Group {
                        HStack(spacing: 0) {
                            Text("Balances")
                                .bold()
                                .font(.system(size: 35))
                                .padding([.top, .leading],5)
                            Spacer()
                            
                            Text("0x")
                            Text(String(format:"%02X", wallet_manager_instance.latest_block_num))
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        HStack(spacing:0) {
                            Button(action: {
                                instance.addBalanceSheet = true
                            }) {
                                HStack(spacing: 2) {
                                    Image(systemName: "plus")
                                    Text("new balance")
                                        .bold()
                                }
                                .foregroundColor(.primary)
                                .font(.subheadline)
                                .padding(.all, 8)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(5)
                                .padding(.leading, 5)
                            }
                            

                            Spacer()
                            Text(String(format: "%.4f", Double(getTotalMCM()) / 1000000000))
                                .padding(.vertical)
                                .foregroundColor(Color("Verde"))
                            Image("mcm-logo-thin-black-scaleable")
                                .resizable()
                                .frame(width: 30,height: 30)
                                .foregroundColor(Color("Verde"))
                                .padding(.trailing, 4)
                        }
                        .background(Color.gray.opacity(0.1))
                        
                        Rectangle()
                            .foregroundColor(.black.opacity(0.7))
                            .frame(height: 1)
                        
                    }
                    ScrollView {
                        
                        ForEach(wallet_manager_instance.open_wallet!.balances, id: \.self) { balance in
                            NavigationLink(destination:  BalanceView(balance: balance)){
                                //BalanceSlotView(bal_id: balance.id, tag: balance.tag, status: balance.status, amount_nmcm: balance.amount_nmcm)
                                BalanceSlotView(balance_data: balance, update: $instance.update_touch)
                            }
                            NavigationLink(destination: EmptyView()) {
                                EmptyView()
                            }
                        }
                        
                        Text("Gift Cards")
                            .bold()
                            .font(.system(size: 25))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .padding(.top, 20)
                            LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
                                ForEach(wallet_manager_instance.open_wallet!.gift_cards, id: \.self) {gift_card in
                                    NavigationLink(destination: GiftCardListView()) {
                                        GiftCardSlotView(gift_card: gift_card)
                                    }
                                }
                            }
                        //Text(String(instance.wallet_data.balances[0].amount_nmcm))
                        //Spacer()
                    }
                    .onTapGesture {
                        instance.update_touch = !instance.update_touch
                    }
                    
                    
                }
                .sheet(isPresented: $scanQR) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
                        .overlay(
                            Rectangle()
                                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5.0,lineCap: .round, lineJoin: .bevel, dash: [50, 150], dashPhase: 25))
                                .frame(width: 200, height: 200)
                        )
                        .overlay(
                            VStack {
                                Text("Searching for QR codes..")
                                    .bold()
                                    .font(.system(size: 30))
                                    .padding()
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                                    .shadow(x: 1, y: 1, blur: 0.5)
                                Spacer()
                            }
                        )
                        .ignoresSafeArea(edges: .bottom)
                }
                
                NavigationLink(destination: BalanceSendView(balances: WalletListManager.singleton.open_wallet!.balances, preferred: nil, destination: open_send_tag), tag: 1, selection: $open_send_link) {
                                        Text("")
                                    }
                Button(action: {
                    scanQR = true
                    print("scan qr")
                }) {
                    Image(systemName: "qrcode")
                        .resizable()
                        .scaledToFit()
                        .padding(.all)
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(.green)
                .cornerRadius(50)
                .offset(y: (geometry.size.height / 2) - 80)

            }
        }
    }
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
       
        switch result {
            case .success(let code):
                print("Found code: \(code)")
                if(code.isHexNumber && code.count == 24 && String(code.prefix(2)) != "00" ) {
                    self.scanQR = false
                    makeSendOpen(dest_tag: code)
                }
            case .failure(let error):
                print(error.localizedDescription)
        }
       // more code to come
    }
    func makeSendOpen(dest_tag: String) {
        print("makesend", dest_tag)
        open_send_tag = dest_tag
        open_send_link = 1
    }
    func getTotalMCM() -> Int {
        var total = 0
        instance.wallet_data.balances.forEach() {bal in
            if(bal.status == 1 && bal.blockStatus == WalletListManager.singleton.latest_block_num) {
                total = total + bal.amount_nmcm
            }
        }
        return total
    }
}

struct BalanceSlotView: View {
    //@State var bal_id: Int
    //@State var tag: String
    //@State var status: Int
    //@State var amount_nmcm: Int
    @ObservedObject var a = WalletListManager.singleton
    @State var balance_data: Balance
    @Binding var update: Bool
    //@ObservedObject var a = WalletListManager.singleton
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("mcm-logo-thin-black-scaleable")
                    .resizable()
                    .scaledToFit()
                    .maxHeight(28)
                    .foregroundColor(Color.systemGreen)
                Text(balance_data.tag)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color("Text"))
                    .padding(.horizontal, 2)
                    .onChange(of: update) {_ in
                        Text("")
                    }
                Spacer()
                if(balance_data.status == 0 || balance_data.status == 10) { // waiting for tag activation
                    ActivityIndicator(isAnimating: .constant(true), customColor: .orange, style: .medium)
                } else if(balance_data.status == 0  && (Int(a.latest_block_num) - Int(balance_data.blockStatus)) > 2) {
                    Text(String(balance_data.amount_nmcm))
                        .foregroundColor(.systemRed)
                    ActivityIndicator(isAnimating: .constant(true), customColor: .red, style: .medium)
                } else if(balance_data.status == 1 && a.latest_block_num != balance_data.blockStatus) {
                    Text(String(balance_data.amount_nmcm))
                        .foregroundColor(.systemGreen)
                    ActivityIndicator(isAnimating: .constant(true), customColor: .black, style: .medium)
                } else if(balance_data.status == 2) {
                    Text(String(balance_data.amount_nmcm))
                        .foregroundColor(.systemYellow)
                    ActivityIndicator(isAnimating: .constant(true), customColor: .yellow, style: .medium)
                } else if(balance_data.status == 12 || balance_data.status == 11) {
                    ActivityIndicator(isAnimating: .constant(true), customColor: .red, style: .medium)
                } else if((Int(a.latest_block_num) - Int(balance_data.blockStatus)) > 5) {
                    ActivityIndicator(isAnimating: .constant(true), customColor: .yellow, style: .medium)
                } else {
                    Text(String(balance_data.amount_nmcm))
                        .foregroundColor(.systemGreen)
                }
            }
            .maxHeight(50)
            .padding(.all)
            Rectangle()
                .foregroundColor(.black.opacity(0.2))
                .frame(height: 1)
        }
    }
}

struct GiftCardSlotView: View {
    @ObservedObject var a = WalletListManager.singleton
    @State var gift_card: GiftCard
    var body: some View {
        HStack {
            Image(systemName: "gift")
                .padding([.leading, .top, .bottom])
            VStack {
                Text("1MCM")
                Text("available")
            }
        }
    }
}

struct NewBalanceView: View {
    @ObservedObject var instance: SecureWalletManager
    @State var balance_tag = ""
    @State var showTagError = false
    @State var showLoading = false
    @State var tagErrorTxt = "this tag is already in use"
    @State var showFundError = false
    @State var fundErrorTxt = "some error"
    @State var fieldFocus = [false, false]

    @State var balance_name = ""
    
    @State var selectedBType = 0
    @State var selectedFountain = "https://wallet.mochimo.com/fund"
    
    init(instance: SecureWalletManager) {
        print("nre balance veiw")
        self.instance = instance
    }
    var body: some View {
        LoadingView(isShowing: $showLoading) {
            VStack {
                HStack {
                    Text("Create balance")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                        .foregroundColor(.blue)
                    Spacer()
                }
                Text("Balance Name")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 5)
                TextField("Balance name", text: $balance_name)
                    .padding(.all)
                    //.background(Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0))
                    .foregroundColor(Color("Textfield"))
                    .cornerRadius(3.0)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                Picker("Balance type", selection: $selectedBType) {
                    Text("TAG").tag(0)
                    Text("Raw WOTS+").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 15)
                
                if(selectedBType == 0) {
                    Text("Balance TAG")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    WithPopover(showPopover: $showTagError,popoverSize: CGSize(width: 230, height: 80),
                        content: {
                            TextField("Wallet TAG", text: $balance_tag)
                                .padding(.all)
                                //.background(Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0))
                                .cornerRadius(3.0)
                                .background(Color.gray.opacity(0.1))
                                .padding(.horizontal)
                                .onAppear() {
                                    if(self.balance_tag == "") {
                                        self.balance_tag = randomTag()
                                    }
                                }
                                .foregroundColor(Color("Textfield"))
                                .onReceive(Just(balance_tag)) { new_value in
                                    let filtered = new_value.filter { "0123456789abcdefABCDEF".contains($0) }
                                    self.balance_tag = filtered.trunc(length: 24)
                                }
                            },
                            popoverContent: {
                                VStack {
                                    Text(tagErrorTxt)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.all)
                                }
                            })
                    
                    HStack {
                        Picker("Fountain: " + selectedFountain, selection: $selectedFountain) {
                            Text("https://wallet.mochimo.com/fund").tag("https://wallet.mochimo.com/fund")
                            Text("http://fountain3.mochimo.com/fund").tag("http://fountain3.mochimo.com/fund")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(.primary)
                        .padding(.all)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(.horizontal)
                    
                } else {
                    Text("RAW WOTS+ IS NOT MOMENTARLY SUPPORTED FOR USER EXPERIENCE REASONS")
                        .padding(.horizontal, 20)
                }
                
                Button(action: {
                    if(selectedBType == 0) {
                        print("going to create a balance with tag")
                        //Check the tag
                        if(!balance_tag.isHexNumber || balance_tag.count != 24) {
                            print("the tag is invalid")
                            tagErrorTxt = "the tag is invalid"
                            showTagError = true
                            return
                        }
                        showLoading = true
                        DispatchQueue.global().async {
                            let group = DispatchGroup()
                            group.enter()
                            var wfound = false
                            //var waddr = [UInt8]()
                            QueryManager.resolveTag(tag: balance_tag.hexaBytes, group: group) {found, wots_addr in
                                print("wujodasno")
                                wfound = found
                                //waddr = wots_addr
                                if(found == true) {
                                    print("this tag is already in use")
                                    tagErrorTxt = "this tag is already in use"
                                    showTagError = true
                                    return
                                }
                                if(wots_addr == nil) {
                                    print("timeout")
                                    tagErrorTxt = "timeout to check tag"
                                    showTagError = true
                                    return
                                }
                            }
                            //wait for the tag result to come
                            group.wait()
                            // now will create the WOTS+ address using the library
                            if(wfound == true) {return}
                            //1/10/2021
                            let balance_id = instance.wallet_data.many_balances
                            //let balance_id = instance.wallet_data.balances.count
                            let wots_id = 0
                            let balance_seed = sha256_hex(data: Data((instance.wallet_data.mnemonic_hash + String(balance_id)).data(using: .ascii)!) as NSData)
                            let wots_seed = sha256_hex(data: Data((balance_seed + String(wots_id)).data(using: .ascii)!) as NSData)
                            let wots_address = WotsClass().generateKeyPairFrom(wots_seed: wots_seed, tag: balance_tag)
                            FountainManager().fund_address(selectedFountain, bytes: wots_address) {status, answer in
                                showLoading = false
                                if(status == false) {
                                    fundErrorTxt = answer
                                    showFundError = true
                                    
                                    return
                                }
                                //Now will add the balance object to the wallet
                                let balance =
                                    Balance(id: balance_id, balance_hash: balance_seed, tag:  balance_tag, wots_address: wots_address, amount_nmcm: 0, status: 0)
                                DispatchQueue.main.async {
                                    instance.wallet_data.many_balances = instance.wallet_data.many_balances + 1
                                    instance.wallet_data.balances.append(balance)
                                    print("saving offline mode")
                                    WalletListManager.singleton.saveWalletsOfflineMode()
                                    print(WalletListManager.singleton.wallet_list)
                                    instance.addBalanceSheet = false
                                }
                                print("Stata fundata")
                                
                            }
                        }
                        
                        
                    }
                }) {
                    Text(selectedBType == 0 ? "CREATE AND FUND" : "ADD WOTS")
                        .bold()
                        .padding(.all)
                        .foregroundColor(.white)
                }
                .background(.blue)
                .cornerRadius(10)
                .shadow(color: .black, radius: 2)
                .padding(.top)
                .alert(isPresented: $showFundError) {
                    Alert(title: Text("Fountain error"), message: Text("The fountain refused to fund the WOTS. "+fundErrorTxt), dismissButton: .default(Text("Got it!")))
                }
                Spacer()
            }

        }
        
    }
    func randomTag() -> String {
        var ret = "03"
        let hex_chars = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"]
        for _ in Range(0...21) {
            ret += hex_chars.randomElement()!
        }
        print(ret)
        return ret
    }
}

struct ChooseMenuFountain: View {
    @Binding var selectedFountain: String
    var body: some View {
        Picker("Fountain", selection: $selectedFountain) {
            Text("https://wallet.mochimo.com/fund").tag("https://wallet.mochimo.com/fund")
        }
        .pickerStyle(MenuPickerStyle())
    }
}
