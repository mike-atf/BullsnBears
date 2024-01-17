//
//  FinHealthListView.swift
//  Bulls'N'Bears
//
//  Created by aDav on 22/03/2023.
//

import SwiftUI
import OSLog

struct FinHealthListView: View {
    
    @ObservedObject var share: Share
    
    @State var healthMoatDataSets: [LabelledChartDataSet]
    @State var pricesTrendDataSets: [LabelledChartDataSet]
    @State var lynchTrendDataSet: [LabelledChartDataSet]
    @State var otherDataSets: [LabelledChartDataSet]
    @State var liquidityDataSets: [LabelledChartDataSet]
    @State var profEfficiencyDataSets: [LabelledChartDataSet]
    
    @State private var healthScore$: String
    @State private var peDisclosure = false
    @State private var liqDisclosure = false
    @State private var solvDisclosure = false
    
    @State private var healthChange = ""
    @State private var moatChange = ""
    @State private var lynchChange = ""
    @State private var stickerChange = ""
    @State private var dcfChange = ""
    @State private var intrinsicChange = ""
    
    @State private var profitabilityChange = ""
    @State private var efficiencyChange = ""
    @State private var quickRatioChange = ""
    @State private var currentRatioChange = ""
    @State private var solvencyChange = ""

    var controller: FinHealthListController
    
    init(share: Share) {
        
        self.share = share
        self.controller = FinHealthListController(share: share)
        self.otherDataSets = [LabelledChartDataSet]()
        self.liquidityDataSets = [LabelledChartDataSet]()
        self.profEfficiencyDataSets = [LabelledChartDataSet]()
        self.healthScore$ = ""
                
        self.healthMoatDataSets = controller.returnTrendDataSet(for: [.healthScore, .moatScore])
        self.pricesTrendDataSets = controller.returnTrendDataSet(for: [.stickerPrice,.dCFValue,.intrinsicValue])
        self.lynchTrendDataSet = controller.returnTrendDataSet(for: [.lynchScore])

    }
    
    var body: some View {
        
            List {
                
                Section {
                    HStack {
                        if healthScore$ == "" {
                            Text("Health score: ")
                                .fontWeight(.bold)
                                .padding(.trailing)
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Health score:")
                                .fontWeight(.bold)
                                .padding(.trailing)
                            Text(healthScore$)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Health & Moat trends")
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: .label))
                        Text("Earliest to last: \(healthChange) / \(moatChange)")
                            .font(.footnote)
                    }

                    MultipleHealthChart(dataSets: healthMoatDataSets, share: share, title: "health & moat")
                        .padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        Text("Key price trends")
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: .label))
                        Text("Sticker: \(stickerChange), DCF: \(dcfChange), Intr.: \(intrinsicChange)")
                            .font(.footnote)
                    }

                    MultipleHealthChart(dataSets: pricesTrendDataSets, share: share, title: "price trend")
                        .padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        
                        Text("Lynch ratio")
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: .label))
                        Text("Earliest to last: \(lynchChange)")
                            .font(.footnote)
                    }

                    MultipleHealthChart(dataSets: lynchTrendDataSet, share: share, title: "lynch")

                }
                
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Profitability & Efficiency")
                                .fontWeight(.bold)
                            Button {
                                peDisclosure.toggle()
                            } label: {
                                Label("", systemImage: peDisclosure ? "chevron.up" : "chevron.down")
                            }
                            
                        }
                        Text("Earliest to last: \(profitabilityChange) / \(efficiencyChange)")
                            .font(.footnote)

                        if peDisclosure {
                            Text("Profitability: Net margin, especially compared to industry peers, related to financial safety; higher means better able to commit capital to growth and expansion.\n\nEfficiency: Operational profit margin after deducting costs of production and marketing. Indicating the management's ability to control costs.")
                                .font(Font.system(size: 11))
                                .padding([.top, .bottom])
                        }
                        let _ = print("calling profitability efficiency with \(profEfficiencyDataSets.count) sets")
                        if profEfficiencyDataSets.count > 1 { // async task below can return single or empty data set after double/ complete dataset received before; this updated the chart as empty.
                            MultipleHealthChart(dataSets: profEfficiencyDataSets, share: share, title: "profitability efficiency")
                        }
                    }.padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Liquidity")
                                .fontWeight(.bold)
                            
                            Button {
                                liqDisclosure.toggle()
                            } label: {
                                Label("", systemImage: liqDisclosure ? "chevron.up" : "chevron.down")
                            }
                            
                        }
                        Text("Earliest to last: \(quickRatioChange) / \(currentRatioChange)")
                            .font(.footnote)
                        if liqDisclosure {
                            Text("Quick ratio = 'Quick assets' / Current liabilities ('Acid test').\nThe ability to quickly use assets convertible to cash to pay current liabilities.\n\nCurrent ratio = 'Current assets' / Current liabilities, a liquidity ratio measuring the ability to pay short-term obligations or those due within one year.")
                                .font(Font.system(size: 11))
                                .padding([.top, .bottom])
                        }
                        if liquidityDataSets.count > 1 { // async task below can return single or empty data set after double/ complete dataset received before; this updated the chart as empty.
                            MultipleHealthChart(dataSets: liquidityDataSets, share: share, title: "liquidity")
                        }
                    }.padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Solvency")
                                .fontWeight(.bold)
                            Button {
                                solvDisclosure.toggle()
                            } label: {
                                Label("", systemImage: solvDisclosure ? "chevron.up" : "chevron.down")
                            }
                            
                        }
                        Text("Earliest to last: \(solvencyChange)")
                            .font(.footnote)

                        if solvDisclosure {
                            Text("Solvency (debt/equity ratio) is the ability to meet debt obligations longer term. Lower is generally better. Solvency is long-term debt divided by assets or equity.\n\nA lower D/E ratio means more of a company's operations are being financed by shareholders rather than by creditors. Good, since shareholders do not charge interest.\n\nD/E ratios vary widely between industries. However, a downward trend over time in the D/E ratio is a good indicator of increasingly solid financial ground.\n\n If a company has a negative D/E ratio, this means it has negative shareholder equity. The liabilities exceed assets. In most cases, this would be considered a sign of high risk and an incentive to seek bankruptcy protection.")
                                .font(Font.system(size: 11))
                                .padding([.top, .bottom])
                        }
                        if otherDataSets.count > 0 {
                            MultipleHealthChart(dataSets: otherDataSets, share: share, title: "other")
                        }
                    }
                }
            }
            .task {
                
                self.healthChange = controller.returnTrendChange(for: .healthScore) ?? "NA"
                self.moatChange = controller.returnTrendChange(for: .moatScore) ?? "NA"
                self.lynchChange = controller.returnTrendChange(for: .lynchScore) ?? "NA"
                self.stickerChange = controller.returnTrendChange(for: .stickerPrice) ?? "NA"
                self.dcfChange = controller.returnTrendChange(for: .dCFValue) ?? "NA"
                self.intrinsicChange = controller.returnTrendChange(for: .intrinsicValue) ?? "NA"

                self.profEfficiencyDataSets = await controller.profitabilityAndEfficiencyData()
                
                let profitabilityData = profEfficiencyDataSets.first!
                self.profitabilityChange = controller.earliestToLatestChange(datedValues: profitabilityData.chartData) ?? ""

                let efficiencyData = profEfficiencyDataSets.last!
                self.efficiencyChange = controller.earliestToLatestChange(datedValues: efficiencyData.chartData) ?? ""
                
                self.liquidityDataSets = await controller.liquidityData()
                self.quickRatioChange = controller.earliestToLatestChange(datedValues: liquidityDataSets.first!.chartData) ?? ""
                self.currentRatioChange = controller.earliestToLatestChange(datedValues: liquidityDataSets.last!.chartData) ?? ""

                let solvencyData = await controller.solvencyData()
                self.otherDataSets.append(solvencyData)
                self.solvencyChange = controller.earliestToLatestChange(datedValues: solvencyData.chartData) ?? ""

                // needs to be last as vaue depends on completed async downloads preceding
                self.healthScore$ = controller.healthScore$()
                
            }
    }
}

struct FinHealthListView_Previews: PreviewProvider {
    static var previews: some View {
        FinHealthListView(share: Share.preview)
    }
}
