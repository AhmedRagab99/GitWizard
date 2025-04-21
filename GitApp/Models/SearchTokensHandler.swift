//
//  SearchTokensHandler.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct SearchTokensHandler {
    static private func newToken(old: [SearchToken], new: [SearchToken]) -> SearchToken? {
        new.first { !old.contains($0) }
    }

    static func handle(oldTokens: [SearchToken], newTokens: [SearchToken]) -> [SearchToken] {
        if let newToken = newToken(old: oldTokens, new: newTokens) {
            switch newToken.kind {
            case .grep, .grepAllMatch:
                return newTokens.map { token in
                    switch token.kind {
                    case .grep, .grepAllMatch:
                        var updateToken = token
                        updateToken.kind = newToken.kind
                        return updateToken
                    case .s, .g, .author, .revisionRange:
                        return token
                    }
                }
            case .s:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .author, .revisionRange:
                        return true
                    case .s:
                        return token == newToken
                    case .g:
                        return false
                    }
                }
            case .g:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .author, .revisionRange:
                        return true
                    case .g:
                        return token == newToken
                    case .s:
                        return false
                    }
                }
            case .author:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .g, .s, .revisionRange:
                        return true
                    case .author:
                        return token == newToken
                    }
                }
            case .revisionRange:
                return newTokens.filter { token in
                    switch token.kind {
                    case .grep, .grepAllMatch, .g, .s, .author:
                        return true
                    case .revisionRange:
                        return token == newToken
                    }
                }
            }
        } else {
            return newTokens
        }
    }
}
