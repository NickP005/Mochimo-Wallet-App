//
//  GiftCardListView.swift
//  Mochimo App
//
//  Created by User on 09/10/21.
//

import SwiftUI

struct GiftCardListView: View {
    @State var currentIndex:Int = 0
    @State var imagesPerTab:Int = 1
    var body: some View {
        GeometryReader { geo in
            // limit image height within 90% of tab height
            // this guarantees the images will not cause a vertical scroll
            let heightPerImage = (geo.size.height * 0.9) / CGFloat(imagesPerTab)
            
            VStack(spacing: 0) {
                // added a button to see effect of adding as many images as wanted
                TabView(selection: $currentIndex.animation()) {
                    ForEach(0 ..< 3, id: \.self) {i in
                        // tab
                        VStack(spacing:0) { // remove vertical spacing between images
                            HStack {
                                Text("GIFT CARD #" + String(i))
                                    .bold()
                                    .font(.system(size: 23))
                                Spacer()
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height - 50)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(20)
                        .padding()
                    }
                    .height(heightPerImage * 0.9)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .background(Color.systemGray5)
                
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }

    }
}

struct GiftCardListView_Previews: PreviewProvider {
    static var previews: some View {
        GiftCardListView()
    }
}
