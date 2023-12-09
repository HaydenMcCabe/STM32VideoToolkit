//
//  RotarySliderBindable.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 8/3/23.
//

import Foundation

protocol RotarySliderBindable: Comparable & Numeric {
    var double: Double {get}
    init(_: Double)
}

//extension Float16: RotarySliderBindable {
//    var double: Double {
//        return Double(self)
//    }
//}

extension Float: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension Double: RotarySliderBindable {
    var double: Double {
        return self
    }
}

extension Int: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension Int32: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension UInt8: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension UInt16: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension UInt32: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

extension UInt64: RotarySliderBindable {
    var double: Double {
        return Double(self)
    }
}

