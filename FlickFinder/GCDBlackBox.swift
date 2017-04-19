//
//  GCDBlackBox.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Modified by Mike Huffaker for Udacity Flick Find project lesson
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void)
{
    DispatchQueue.main.async
    {
        updates()
    }
}
