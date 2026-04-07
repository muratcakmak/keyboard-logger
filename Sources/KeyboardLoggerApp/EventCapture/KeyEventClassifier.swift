import CoreGraphics

public enum ClassifiedEvent: Sendable {
    case shortcut(combo: String, appBundleID: String, appName: String)
    case plainKey(key: String, appBundleID: String)
}

enum KeyEventClassifier {

    static func classify(
        keyCode: Int64,
        flags: CGEventFlags,
        appBundleID: String,
        appName: String
    ) -> ClassifiedEvent {
        let hasCmd = flags.contains(.maskCommand)
        let hasCtrl = flags.contains(.maskControl)
        let hasAlt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)

        let keyName = keyCodeToName(keyCode)

        // A shortcut requires at least Cmd, Ctrl, or Alt (Shift alone is just typing)
        let isShortcut = hasCmd || hasCtrl || hasAlt

        if isShortcut {
            var parts: [String] = []
            if hasCtrl { parts.append("ctrl") }
            if hasAlt { parts.append("alt") }
            if hasShift { parts.append("shift") }
            if hasCmd { parts.append("cmd") }
            parts.append(keyName)

            let combo = parts.joined(separator: "+")
            return .shortcut(combo: combo, appBundleID: appBundleID, appName: appName)
        } else {
            return .plainKey(key: keyName, appBundleID: appBundleID)
        }
    }

    // MARK: - Key Code Mapping

    private static func keyCodeToName(_ code: Int64) -> String {
        switch code {
        // Letters
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "o"
        case 32: return "u"
        case 33: return "["
        case 34: return "i"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 39: return "'"
        case 40: return "k"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "n"
        case 46: return "m"
        case 47: return "."
        case 50: return "`"

        // Special keys
        case 36: return "return"
        case 48: return "tab"
        case 49: return "space"
        case 51: return "delete"
        case 53: return "escape"
        case 71: return "clear"
        case 76: return "enter"

        // Modifiers (standalone, shouldn't normally reach here for combos)
        case 55: return "command"
        case 56: return "shift"
        case 57: return "capslock"
        case 58: return "option"
        case 59: return "control"
        case 60: return "rightshift"
        case 61: return "rightoption"
        case 62: return "rightcontrol"
        case 63: return "fn"

        // Arrow keys
        case 123: return "left"
        case 124: return "right"
        case 125: return "down"
        case 126: return "up"

        // Function keys
        case 122: return "f1"
        case 120: return "f2"
        case 99: return "f3"
        case 118: return "f4"
        case 96: return "f5"
        case 97: return "f6"
        case 98: return "f7"
        case 100: return "f8"
        case 101: return "f9"
        case 109: return "f10"
        case 103: return "f11"
        case 111: return "f12"

        // Numpad
        case 65: return "numpad."
        case 67: return "numpad*"
        case 69: return "numpad+"
        case 75: return "numpad/"
        case 78: return "numpad-"
        case 81: return "numpad="
        case 82: return "numpad0"
        case 83: return "numpad1"
        case 84: return "numpad2"
        case 85: return "numpad3"
        case 86: return "numpad4"
        case 87: return "numpad5"
        case 88: return "numpad6"
        case 89: return "numpad7"
        case 91: return "numpad8"
        case 92: return "numpad9"

        // Media
        case 10: return "§"
        case 114: return "help"
        case 115: return "home"
        case 116: return "pageup"
        case 117: return "forwarddelete"
        case 119: return "end"
        case 121: return "pagedown"

        default: return "key\(code)"
        }
    }
}
