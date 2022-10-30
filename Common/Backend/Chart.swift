//
//  Chart.swift
//  KaniManabu
//
//  Created by 千代田桃 on 9/25/21.
//  Copyright © 2022 MAL Updater OS X Group. All rights reserved.
//

#if canImport(Charts)
import SwiftUI
import Charts
#endif

struct Datapoint: Identifiable {
    var label: String
    var value: Double
    var id = UUID()
}

struct StackedDatapoint: Identifiable {
    var label: String
    var value1: Double
    var value2: Double
    var id = UUID()
}

@objc public class ChartCreator: NSObject {
    @objc func generateBarChart(data: NSString) -> NSViewController? {
        if #available(macOS 13, *) {
            let ndata : String = data as String
            if let data = ndata.data(using: .utf8) {
                do {
                    let parseddata = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Double]
                    let cdata = convertDataPoints(data: parseddata!, isScoreChart: false)
                    let chart = Chart {
                        ForEach(cdata) { Datapoint in
                            BarMark(
                                x: .value("Label", Datapoint.label),
                                y: .value("Value", Datapoint.value)
                            )
                        }
                    }
                    return NSHostingController(rootView: chart)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        }
        return nil
        
    }
    
    @objc func generateStackedBarLineChart(data: NSString) -> NSViewController? {
        if #available(macOS 13, *) {
            let ndata : String = data as String
            if let data = ndata.data(using: .utf8) {
                do {
                    let parseddata = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Dictionary<String, Double>]
                    let cdata = convertStackedDataPoints(data: parseddata!)
                    let chart = Chart {
                        ForEach(cdata) { Datapoint in
                            BarMark(
                                x: .value("Label", Datapoint.label),
                                y: .value("Value1", Datapoint.value1)
                            )
                            LineMark(
                                x: .value("Label", Datapoint.label),
                                y: .value("Value2", Datapoint.value2)
                            )
                        }
                    }
                    return NSHostingController(rootView: chart)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        }
        return nil
        
    }
    
    @objc func generateSingleBarChart(data: NSString) -> NSViewController? {
        if #available(macOS 13, *) {
            let ndata : String = data as String
            if let data = ndata.data(using: .utf8) {
                do {
                    let parseddata = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Double]
                    let cdata = convertDataPoints(data: parseddata!, isScoreChart: false)
                    let chart = Chart {
                        ForEach(cdata) { Datapoint in
                            BarMark(
                                x: .value("Value", Datapoint.value)
                            )
                            .foregroundStyle(by: .value("Label", Datapoint.label))
                        }
                    }
                    return NSHostingController(rootView: chart)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        }
        return nil
        
    }
    
    func convertDataPoints(data : Dictionary<String, Double>, isScoreChart: Bool) -> Array<Datapoint> {
        var tarray = [Datapoint]()
        let sortedKeys = isScoreChart ? ["10", "9", "8", "7", "6", "5", "4", "3", "2", "1"] : Array(data.keys).sorted(by: <)
        sortedKeys.forEach { key in
            tarray.append(Datapoint.init(label: key, value: data[key] ?? 0))
        }
        return tarray
    }
    
    func convertStackedDataPoints(data : Dictionary<String, Dictionary<String, Double>>) -> Array<StackedDatapoint> {
        var tarray = [StackedDatapoint]()
        let sortedKeys = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48"]
        sortedKeys.forEach { key in
            tarray.append(StackedDatapoint.init(label: key, value1: data[key]!["value1"] ?? 0, value2: data[key]!["value2"] ?? 0))
        }
        return tarray
    }
}

