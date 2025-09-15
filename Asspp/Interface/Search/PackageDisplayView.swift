//
//  PackageDisplayView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

struct PackageDisplayView: View {
    let archive: AppStore.AppPackage
    let style: DisplayStyle

    enum DisplayStyle {
        case compact
        case detail
    }

    var body: some View {
        switch style {
        case .compact:
            HStack(spacing: 8) {
                KFImage(URL(string: archive.software.artworkUrl))
                    .antialiased(true)
                    .resizable()
                    .cornerRadius(8)
                    .frame(width: 32, height: 32, alignment: .center)
                VStack(alignment: .leading, spacing: 2) {
                    Text(archive.software.name)
                        .font(.system(.body, design: .rounded))
                        .bold()
                    Group {
                        Text("\(archive.software.bundleID) \(archive.software.version)")
                    }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .detail:
            VStack(alignment: .leading, spacing: 8) {
                KFImage(URL(string: archive.software.artworkUrl))
                    .antialiased(true)
                    .resizable()
                    .cornerRadius(8)
                    .frame(width: 50, height: 50, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(archive.software.name)
                    .bold()
                if !archive.software.description.isEmpty {
                    Text(archive.software.description)
                        .font(.system(.footnote, design: .rounded))
                }
            }
            .padding(.vertical, 4)
        }
    }
}
