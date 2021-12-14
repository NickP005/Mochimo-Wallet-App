//
//  LoadingScreen.swift
//  Mochimo App
//
//  Created by User on 03/09/21.
//

import Foundation
import SwiftUI
import UIKit

struct LoadingScreen: View {
    
    var body: some View {
        VStack {
            Text("")
                .frame(maxHeight: .infinity)
            HStack {
                Image("mcm-logo-thin-black-scaleable")
                    .resizable()
                    .scaledToFit()
                Text("Mochimo wallet Beta v0.1")
                    .font(.system(size: 30))
            }
            .frame(maxHeight: 80, alignment: .center)
            
            HStack {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text("loading...")
                    .font(.system(size: 18))
            }
            .frame(maxHeight: 80, alignment: .center)
            Text("")
                .frame(maxHeight: .infinity)
        }
        
    }
}

struct LoadingScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreen()
    }
}

struct LoadingView<Content>: View where Content: View {

    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)

                VStack {
                    Text("Working...")
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)

            }
        }
    }

}
struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    @State var customColor: UIColor = UIColor.black
    
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        if(customColor == UIColor.black) {
            return UIActivityIndicatorView(style: style)
        } else {
            let indicator = UIActivityIndicatorView(style: style)
            indicator.assignColor(customColor)
            return indicator

        }
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

extension UIActivityIndicatorView {
    func assignColor(_ color: UIColor) {
        style = .medium
        self.color = color
    }
}
