//
//  KeychainHelper.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/07.
//

import Foundation
import Security

class KeychainHelper {
    
    // Keychain에 데이터 저장
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("❌ Keychain 저장 실패: 데이터 변환 오류")
            return false
        }
        
        // 기존 항목 삭제
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: false  // iCloud 동기화 비활성화
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain 저장 성공: \(key)")
            return true
        } else {
            print("❌ Keychain 저장 실패: \(status)")
            return false
        }
    }
    
    // Keychain에서 데이터 로드
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                print("⚠️ Keychain 로드 실패: \(status)")
            }
            return nil
        }
        
        print("✅ Keychain 로드 성공: \(key)")
        return value
    }
    
    // Keychain에서 데이터 삭제
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
