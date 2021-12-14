//
//  BalanceView.swift
//  Mochimo App
//
//  Created by User on 14/09/21.
//

import SwiftUI
import Foundation
import CoreImage.CIFilterBuiltins
import Combine

struct BalanceView: View {
    @State var scroll: CGFloat = 200
    @State var scroll_status = 1
    @State var balance: Balance
    @State var action_choose_bx: Bool = false
    
    @State var auto_close_new_gift_card = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        if(scroll_status != 2) {
                            Image(uiImage: generateQRCode(from: balance.tag))
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(10)
                                .padding(.all)
                        }
                    }
                    .maxWidth(.infinity)
                    .height(scroll)
                    .onTapGesture {
                        scroll_status = 0
                        withAnimation {
                            scroll = 500
                        }
                    }
                    Spacer()
                }
                
                
                VStack{
                    Image(systemName: "chevron.up")
                        .resizable()
                        .frame(width: 50, height: 20)
                        .scaledToFit()
                        .foregroundColor(Color("Text"))
                        .padding(.all)
                    HStack {
                        Text(balance.tag)
                            .bold()
                            .font(.system(size: 20))
                            .padding(.leading)
                        Button(action: {
                            UIPasteboard.general.string = balance.tag
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Spacer()
                            Image(systemName: "doc.on.doc.fill")
                                .resizable()
                                .frame(width: 12, height: 15)
                                .scaledToFit()
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(width: 15, height: 15)
                        .padding(.all, 5)
                        .background(.blue)
                        .cornerRadius(50)
                        Spacer()
                    }
                    HStack {
                        Text(String(format: "%.9f", Double(balance.amount_nmcm) / 1000000000))
                        Text(" MCM")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    Button(action: {
                        action_choose_bx = true
                    }) {
                        HStack {
                            Text("View in")
                            Image(systemName: "arrowshape.turn.up.right")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .actionSheet(isPresented: $action_choose_bx, content: {
                            ActionSheet(
                                title: Text("Open in block explorer"),
                                message: Text("Select the block explorer"),
                                buttons: [
                                    .default(Text("mochimap.com")) {
                                        guard let url = URL(string: "https://www.mochimap.com/explorer/ledger/tag/" + balance.tag) else { return }
                                        UIApplication.shared.open(url)
                                    },
                                    .default(Text("bx.mochimo.org")) {
                                        guard let url = URL(string: "https://bx.mochimo.org/tag/" + balance.tag) else { return }
                                        UIApplication.shared.open(url)
                                    },
                                    .cancel()
                                ])
                    })
                    HStack {
                        NavigationLink(destination: BalanceSendView(balances: WalletListManager.singleton.open_wallet!.balances, preferred: balance.tag)) {
                            Text("SEND")
                                .bold()
                                .foregroundColor(.white)
                                .padding(.all)
                        }
                        .background(.accentColor)
                        .cornerRadius(8)
                        .padding(.all)
                        
                        NavigationLink(destination: GiftCardCreateView(balances: WalletListManager.singleton.open_wallet!.balances)) {
                            HStack(spacing: 5) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.white)
                                    .padding([.top, .bottom, .leading])
                                Text("GIFT")
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding([.top, .bottom, .trailing])
                            }
                        }
                        .background(.accentColor)
                        .cornerRadius(8)
                        .padding([.top, .bottom, .trailing])

                        Spacer()
                    }
                    
                    VStack {
                        Text("Balance information")
                            .bold()
                            .padding(.bottom)
                        HStack(spacing: 0) {
                            Text("Spent ")
                            Text(String(balance.many_spent))
                            Text(" times")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 0) {
                            Text("Last data update on block 0x")
                            Text(String(format:"%02X", balance.blockStatus))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 0) {
                            Text("(DEBUG) status:")
                            Text(String(balance.status))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Group {
                            if(balance.status == 0) {
                                Text("The balance is getting funded by the chosen fountain")
                                    .foregroundColor(.yellow)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if(balance.status == 1) {
                                Text("The balance is ready for operations")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if(balance.status == 2) {
                                Text("The balance is currently under the process of sending a transaction")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if(balance.status == 11) {
                                Text("Something went wrong while nothing should have happened")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if((Int(WalletListManager.singleton.latest_block_num) - Int(balance.blockStatus)) < 3) {
                                    HStack(spacing: 0) {
                                        Text("Will try to recover the WOTS in ")
                                        Text(String(Int(3) - Int(WalletListManager.singleton.latest_block_num - balance.blockStatus)))
                                        Text(" blocks")
                                    }
                                }
                            } else if(balance.status == 12) {
                                Text("Something went wrong sending while sending the transaction.")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if((Int(WalletListManager.singleton.latest_block_num) - Int(balance.blockStatus)) < 3) {
                                    HStack(spacing: 0) {
                                        Text("Will try to recover the precedent WOTS in ")
                                        Text(String(Int(3) - Int(WalletListManager.singleton.latest_block_num - balance.blockStatus)))
                                        Text(" blocks")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .maxWidth(.infinity)
                //.height(geometry.size.height - scroll)
                .cornerRadius([.topLeft, .topRight], 15)
                .background(Color("Background-pulito"))
                .cornerRadius([.topLeft, .topRight], 15)

                .height(700)
                .offset(y: scroll)
            }
            .maxWidth(.infinity)
            .maxHeight(.infinity)
            //.frame(height: geometry.size.height)
            .background(.systemGray2.opacity(0.2))
            .onTapGesture {
                if(scroll_status == 0) {
                    scroll_status = 1
                    withAnimation {
                        scroll = 200
                    }
                }
            }

        }
        .gesture(
           DragGesture().onEnded { value in
            //Now will define various statuses of showing
            // 0. QR code is visible
            // 1. Both QRCode and down view are visible
            // 2. QRCode is on the top, as invisible
            if(scroll_status == 1) {
                if(value.translation.height > 200) {
                    scroll_status = 0
                } else if(value.translation.height < -200) {
                    scroll_status = 2
                }
            }
            if(scroll_status == 0) {
                if(value.translation.height < -200) {
                    scroll_status = 1
                }
            }
            if(scroll_status == 2) {
                if(value.translation.height > 150) {
                    scroll_status = 1
                }
            }
            if(scroll_status == 0) {
                withAnimation {
                    scroll = 500
                }
            }
            if(scroll_status == 1) {
                withAnimation {
                    scroll = 200
                }
            }
            if(scroll_status == 2) {
                withAnimation {
                    scroll = 50
                }
            }
            print("scroll", scroll, scroll_status)
              if value.translation.height > 0 {
                print("satro Scroll down", value.translation.height)
              } else {
                 print("satro Scroll up", value.translation.height)
              }
           }
        )
    }
    private var axes: Axis.Set {
        return scroll_status == 2 ? .vertical : []
    }
}
/*
struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceView()
    }
}
*/
func generateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let data = Data(string.utf8)
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    if let outputImage = filter.outputImage {
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }

    return UIImage(systemName: "xmark.circle") ?? UIImage()
}

struct BalanceSendView: View {

    @State var balances: [Balance]
    @State var destination_tag: String
    @State var last_destination_tag: String = ""
    @State var send_amount_str: String = ""
    @State var balance_selection: String
    @State var balance_exists: Bool = false
    @State var balance_exists_status: Int = 0
    @State var destination_wots = [UInt8]()
    @State var pop_source_tag: Bool = false
    @State var pop_source_text: String = "please select a valid source tag"
    @State var pop_send_amount: Bool = false
    @State var pop_nodestroy: Bool = false
    @State var pop_destination_tag: Bool = false
    @State var pop_sent_tx: Bool = false
    init(balances: [Balance], preferred: String? = nil, destination: String? = nil) {
        self.balances = balances
        if(preferred == nil) {
            self.balance_selection = balances.randomElement()?.tag ?? ""
        } else {
            self.balance_selection = preferred!
        }
        if(destination == nil) {
            self.destination_tag = ""
        } else {
            self.destination_tag = destination!
        }
    }
    var body: some View {
        Form {
            Section(header: Text("Source " + getnMCM(tag: balance_selection))) {
                WithPopover(showPopover: $pop_source_tag,popoverSize: CGSize(width: 260, height: 40),
                            content: {
                                Picker(selection: $balance_selection, label: Text("tag")) {
                                    ForEach(balances, id: \.self) { bal in
                                        if(bal.amount_nmcm > 500 && bal.status == 1) {
                                            Text(bal.tag)
                                            .tag(bal.tag)
                                        }
                                    }
                                }
                                .onReceive(Just(balance_selection)) { new_value in
                                    if(balances.first(where: {$0.tag == balance_selection})?.status != 1) {
                                        balance_selection = ""
                                    }
                                }
                            }, popoverContent: {
                                Text(pop_source_text)
                                    .foregroundColor(.red)
                                    
                            })
                    .alert(isPresented: $pop_nodestroy) {
                        Alert(
                            title: Text("Cannot proceed"),
                            message: Text("This action will destroy the balance tag and for safety reasons it is not yet supported."),
                            dismissButton: .default(Text("Got it!"))
                        )
                        
                    }
                    .alert(isPresented: $pop_sent_tx) {
                        Alert(
                            title: Text("Success!"),
                            message: Text("Successfully sent the transaction! Please close this send page."),
                            dismissButton: .default(Text("Got it!"))
                        )
                        
                    }
                WithPopover(showPopover: $pop_send_amount,popoverSize: CGSize(width: 230, height: 80),
                            content: {
                                HStack {
                                    TextField("Send amount", text: $send_amount_str)
                                        .keyboardType(.decimalPad)
                                        .onReceive(Just(send_amount_str)) { newValue in
                                            var filtered = newValue.replacingOccurrences(of: ",", with: ".")
                                            filtered = filtered.filter { "0123456789.".contains($0) }
                                            if(filtered == ".") {
                                                filtered = "0."
                                            }
                                            filtered = filtered.replacingOccurrences(of: "..", with: ".")
                                            
                                            if(filtered.prefix(2) == "00") {
                                                filtered.remove(at: filtered.index(filtered.startIndex, offsetBy: 0))
                                            }
                                            
                                            var jolly = false
                                            for (index, char) in filtered.enumerated() {
                                                //print("index = \(index), character = \(char)")
                                                if(char == ".") {
                                                    if(jolly) {
                                                        filtered.remove(at: filtered.index(filtered.startIndex, offsetBy: index))
                                                    } else {
                                                        jolly = true
                                                    }
                                                }
                                            }
                                            var comma_from = -1
                                            for (index, char) in filtered.enumerated() {
                                                //print("index = \(index), character = \(char)")
                                                if(char == ".") {
                                                    comma_from = 0
                                                }
                                                if(comma_from >= 0) {
                                                    comma_from = comma_from + 1
                                                }
                                                if(comma_from > 10) {
                                                    filtered.remove(at: filtered.index(filtered.startIndex, offsetBy: 11))
                                                }
                                            }
                                            if filtered != newValue {
                                                self.send_amount_str = filtered
                                            }
                                
                                        }
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                    Text("MCM")
                                }
                            }, popoverContent: {
                                Text("Please input a valid amount")
                                    .foregroundColor(.red)
                            })
            }
            Section(header: Text("Destination")) {
                HStack {
                    WithPopover(showPopover: $pop_destination_tag ,popoverSize: CGSize(width: 230, height: 80),
                                content: {
                                    TextField("tag destination", text: $destination_tag)
                                        .onReceive(Just(destination_tag)) { new_value in
                                            let filtered = new_value.filter { "0123456789abcdefABCDEF".contains($0) }
                                            self.destination_tag = filtered.trunc(length: 24)
                                            if(self.destination_tag == last_destination_tag) {
                                                return
                                            }
                                            self.last_destination_tag = filtered.trunc(length: 24)
                                            if(self.destination_tag.count == 24) {
                                                if(balance_exists_status != 1) {
                                                    balance_exists_status = 1
                                                }
                                                checkTag()
                                                
                                            } else {
                                                balance_exists = false
                                                balance_exists_status = 0
                                            }
                                        }
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }, popoverContent: {
                                    Text("Invalid destination tag")
                                        .foregroundColor(.red)
                                })
                    if(balance_exists_status == 0) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                    } else if(balance_exists_status == 1) {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else if(balance_exists_status == 2) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
                
                
                    
            }
            .onAppear() {
                if(self.destination_tag.count != 24) {
                    return
                }
                if(balance_exists_status != 1) {
                    balance_exists_status = 1
                }
                //checkTag()
            }
            Button(action: {
                print("button send transaction, latest block num = ", WalletListManager.singleton.latest_block_num)
                //First of all check if the destination tag works
                if(destination_tag.count != 24 || balance_exists != true) {
                    print("cannot do the transaction", balance_exists)
                    pop_destination_tag = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    return
                }
                //Now proceed to generate the wots signature
                var balance = balances.first(where: {$0.tag == balance_selection})
                guard let balance = balance else {
                    print("ERROR: something went wrong getting balance data")
                    pop_source_tag = true
                    pop_source_text = "please select a valid tag"
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    return
                }
                if(balance.status != 1) {
                    print("ERROR: cannot send transaction when balance isn't in status 1")
                    return
                }
                if(balance.amount_nmcm < Int((Double(send_amount_str) ?? 100000000) * 1000000000)) {
                    print("USER ERROR: the input for send mcm is too large", balance.amount_nmcm, "vs", (Double(send_amount_str) ?? 100000000) * 1000000000)
                    pop_send_amount = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    return
                }
                let send_amount = Int(Double(send_amount_str)! * 1000000000)
                if(balance.amount_nmcm - send_amount - 500 <= 500) {
                    print("ERROR: Cannot proceed to send transaction cause the resulting balance would be less than 500nMCM")
                    pop_nodestroy = true
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    return
                }
                let wots_id = balance.many_spent + 1
                let wots_seed = sha256_hex(data: Data((balance.balance_hash + String(wots_id)).data(using: .ascii)!) as NSData)
                let group = DispatchGroup()
                group.enter()
                var change_address = [UInt8]()
                DispatchQueue.global().async {
                    change_address = WotsClass().generateKeyPairFrom(wots_seed: wots_seed, tag: balance.tag)
                    group.leave()
                }
                group.wait()
                let source_address = balance.wots_address
                let destination_address = destination_wots
                //Now we have to generate the signature
                QueryManager.sendTransaction(from: source_address, to: destination_address, change: change_address, amount: UInt(balance.amount_nmcm), send: UInt(send_amount), seed: sha256_hex(data: Data((balance.balance_hash + String(balance.many_spent)).data(using: .ascii)!) as NSData))
                //then we modify the balance values with the new ones
                balance.amount_nmcm = balance.amount_nmcm - send_amount - 500
                balance.status = 2
                balance.many_spent = wots_id
                print("before blockstatus was", balance.blockStatus, "now it is", WalletListManager.singleton.latest_block_num)
                balance.blockStatus = WalletListManager.singleton.latest_block_num
                //balance.balance_hash = wots_seed
                balance.wots_address = change_address
                WalletListManager.singleton.saveWalletsOfflineMode()
                balance_selection = ""
                pop_sent_tx = true
                //UIImpactFeedbackGenerator(style: .).impactOccurred()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("SEND TRANSACTION")
                    .bold()
            }
        }
    }
    func getnMCM(tag: String) -> String {
        return String(format: "%.9f", Double(balances.first(where: {$0.tag == balance_selection})?.amount_nmcm ?? 0) / 1000000000) + " MCM"
    }
    func checkTag() {
        DispatchQueue.global().async {
            QueryManager.resolveTag(tag: destination_tag.hexaBytes, group: nil) {found, wots_addr in
                //waddr = wots_addr
                if(found == true) {
                    print("this destination tag exists")
                    destination_wots = wots_addr!
                    DispatchQueue.main.async {
                        balance_exists = true
                        balance_exists_status = 2
                    }
                    return
                }
                if(wots_addr == nil) {
                    print("timeout")
                    balance_exists = false
                    balance_exists_status = 0
                    return
                } else if(found == false) {
                    print("this destination tag doesn't exist")
                    DispatchQueue.main.async {
                        balance_exists = false
                        balance_exists_status = 0
                    }
                }
            }
        }
    }
}

struct GiftCardCreateView: View {
    @State var balances: [Balance]
    @State var gift_seed: String = ""
    @State var balance_selection: String = ""
    @State var selected_balance: Balance? = nil
    @State var balance_sel_status = 0
    @State var amount_input: String = ""
    @State var pop_sent_tx = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .resizable()
                .scaledToFit()
                .padding(.top, 30)
                .padding(.horizontal, 40)
                .foregroundColor(.red)
                .onAppear() {
                    if(gift_seed == "") {
                        gift_seed = "mochigift_" + String.random(length: 15)
                    }
                }
                .alert(isPresented: $pop_sent_tx) {
                    Alert(
                        title: Text("Success!"),
                        message: Text("Successfully created the gift card! Please close this send page."),
                        dismissButton: .default(Text("Got it!"))
                    )
                    
                }
            Text("Choose the source tag ")
                .bold()
                .font(.system(size: 20))
            if(selected_balance == nil) {
                Text("Please select a source")
                    .padding(.top, -10)
            } else if(selected_balance?.amount_nmcm ?? 0 < 1000001001) {
                Text("The source must have at least 1MCM")
                    .padding(.top, -10)
            } else if(selected_balance?.amount_nmcm ?? 0 < ((Int(amount_input ) ?? 1000000000) * 1000000000 - 1001)) {
                Text("The source must have at least the gift amount..")
                    .padding(.top, -10)
            }
            Picker(selection: $balance_selection, label: Text("source tag " + balance_selection)) {
                ForEach(balances, id: \.self) { bal in
                    if(bal.amount_nmcm > 500 && bal.status == 1) {
                        Text(bal.tag)
                        .tag(bal.tag)
                    }
                }
            }
            .onReceive(Just(balance_selection)) { new_value in
                var balance = balances.first(where: {$0.tag == balance_selection})
                guard let balance = balance else {
                    selected_balance = nil
                    return
                }
                selected_balance = balance
            }
            .padding(.horizontal)
            .pickerStyle(MenuPickerStyle())
            TextField("gift sizeSend amount", text: $amount_input)
                .keyboardType(.numberPad)
                .onReceive(Just(amount_input)) { newValue in
                    var filtered = newValue.filter { "0123456789.".contains($0) }.replacingOccurrences(of: ",", with: "")
                    if(Int(filtered) ?? 1 < 1 && filtered.count > 1) {
                        filtered = "1"
                    }
                    if(Int(filtered) != nil) {
                        self.amount_input = String(Int(filtered) ?? 1)
                    }
                }
                .modifier(customViewModifier(roundedCornes: 6, startColor: .orange, endColor: .purple, textColor: .white))
                .multilineTextAlignment(.center)
                .padding(.all)
            Button(action: {
                print("going to create the gift card")
                var balance = balances.first(where: {$0.tag == balance_selection})
                guard let balance = balance else {
                    print("ERROR: something went wrong getting balance data")
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    return
                }
                if(balance.status != 1) {
                    print("ERROR: cannot send transaction when balance isn't in status 1")
                    return
                }
                if(balance.amount_nmcm < 1000001001) {
                    return
                }
                if(Int(amount_input) == nil) { return }
                if(balance.amount_nmcm < (Int(amount_input)! * 1000000000 - 1001)) {
                    print("much would disintegrate")
                    return
                }
                let gift = GiftCard(amount_nmcm: Int(amount_input)!, gift_seed: gift_seed)
                //now will send the mochimos to the designed wots
                let wots_id = balance.many_spent + 1
                let wots_seed = sha256_hex(data: Data((balance.balance_hash + String(wots_id)).data(using: .ascii)!) as NSData)
                let group = DispatchGroup()
                group.enter()
                var change_address = [UInt8]()
                DispatchQueue.global().async {
                    change_address = WotsClass().generateKeyPairFrom(wots_seed: wots_seed, tag: balance.tag)
                    group.leave()
                }
                group.wait()
                
                let source_address = balance.wots_address
                let destination_address = gift.wots
                let send_amount = Int(amount_input)! * 1000000000
                //Now we have to generate the signature
                QueryManager.sendTransaction(from: source_address, to: destination_address, change: change_address, amount: UInt(balance.amount_nmcm), send: UInt(send_amount), seed: sha256_hex(data: Data((balance.balance_hash + String(balance.many_spent)).data(using: .ascii)!) as NSData))
                balance.amount_nmcm = balance.amount_nmcm - send_amount - 500
                balance.status = 2
                balance.many_spent = wots_id
                print("before blockstatus was", balance.blockStatus, "now it is", WalletListManager.singleton.latest_block_num)
                balance.blockStatus = WalletListManager.singleton.latest_block_num
                //balance.balance_hash = wots_seed
                balance.wots_address = change_address
                //now add the gift card to the wallet
                WalletListManager.singleton.open_wallet!.gift_cards.append(gift)
                WalletListManager.singleton.saveWalletsOfflineMode()
                balance_selection = ""
                pop_sent_tx = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Text("Create gift card")
                    .font(.system(size: 20))
                    .foregroundColor(balance_selection == "" ? Color("Text").opacity(0.5) : Color("Text").opacity(0.95))
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                    .background(colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.2))
                    .cornerRadius(20)
            }
            .disabled(balance_selection == "" || selected_balance?.amount_nmcm ?? 0 < 1000001001)
            Spacer()
        }
    }
    struct customViewModifier: ViewModifier {
        var roundedCornes: CGFloat
        var startColor: Color
        var endColor: Color
        var textColor: Color
        
        func body(content: Content) -> some View {
            content
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [startColor, endColor]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(roundedCornes)
                .padding(3)
                .foregroundColor(textColor)
                .overlay(RoundedRectangle(cornerRadius: roundedCornes)
                            .stroke(LinearGradient(gradient: Gradient(colors: [startColor, endColor]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5))
                .font(.custom("Open Sans", size: 18))
                
                .shadow(radius: 10)
        }
    }
}
