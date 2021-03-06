//
//  UIViewExtension.swift
//  Longinus
//
//  Created by Qitao Yang on 2020/5/14.
//
//  Copyright (c) 2020 KittenYang <kittenyang@icloud.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

extension LonginusExtension where Base: UIView {
    public enum FillContentMode {
        /// Aligns center and aspect fill
        case center
        
        /// Aligns top and aspect fill
        case top
        
        /// Aligns bottom and aspect fill
        case bottom
        
        /// Aligns left and aspect fill
        case left
        
        /// Aligns right and aspect fill
        case right
        
        /// Aligns top left and aspect fill
        case topLeft
        
        /// Aligns top right and aspect fill
        case topRight
        
        /// Aligns bottom left and aspect fill
        case bottomLeft
        
        /// Aligns bottom right and aspect fill
        case bottomRight
    }
    
}
