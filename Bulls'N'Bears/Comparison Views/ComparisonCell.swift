//
//  ComparisonCell.swift
//  Bulls'N'Bears
//
//  Created by aDav on 28/04/2021.
//

import UIKit

class ComparisonCell: UITableViewCell {

    @IBOutlet var rowTitleLabel: UILabel!
    
    var valueLabels: [UILabel]?
    var labelBackgroundViews: [UIView]?
    var legendLabel: UILabel?
    var textViews: [UITextView]?
    var charts: [ValueChart]?
    var cellShowsCharts = false
//    var trendIcons: [TrendIconView2]?
    var controller: ComparisonController!
    
    let columnWidth: CGFloat = 150
    let firstColumnInset: CGFloat = 350
    var margins: UILayoutGuide!
    let financialsFontSize: CGFloat = 20
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        rowTitleLabel.numberOfLines = 0
        rowTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
    
    override func prepareForReuse() {
        rowTitleLabel.text = "Row title"
        for constraint in legendLabel?.constraints ?? [] {
            legendLabel?.removeConstraint(constraint)
        }
        legendLabel?.removeFromSuperview()
        
        for label in valueLabels ?? [] {
            label.removeFromSuperview()
        }
        for view in labelBackgroundViews ?? [] {
            view.removeFromSuperview()
        }
        for view in textViews ?? [] {
            view.removeFromSuperview()
        }
        cellShowsCharts = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(controller: ComparisonController, cellPath: IndexPath) {
        
        self.controller = controller
        margins = contentView.layoutMarginsGuide
        rowTitleLabel.text = controller.titleForRow(for: cellPath)

        layoutCell(cellPath: cellPath)
    }
    
    func layoutCell(cellPath: IndexPath) {
        
        for constraint in legendLabel?.constraints ?? [] {
            legendLabel?.removeConstraint(constraint)
        }
        legendLabel?.removeFromSuperview()

        for label in valueLabels ?? [] {
            label.removeFromSuperview()
        }

        for view in labelBackgroundViews ?? [] {
            view.removeFromSuperview()
        }

        for chart in charts ?? [] {
            chart.removeFromSuperview()
        }
        
        if cellPath == IndexPath(row: 0, section: 0) {
            createTextView(cellPath: cellPath)
        }
        else if cellPath.section < 3 {
            createLabels(cellPath: cellPath)
        }
        else if cellShowsCharts {
            legendLabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: financialsFontSize)
                label.text = "Compound growth"
                label.textAlignment = .right
                label.numberOfLines = 0
                label.sizeToFit()
                return label
            }()
            self.contentView.addSubview(legendLabel!)
            legendLabel!.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset-10).isActive = true
            legendLabel!.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            legendLabel!.leadingAnchor.constraint(greaterThanOrEqualTo: rowTitleLabel.trailingAnchor, constant: 10).isActive = true
            
            chartsView(cellPath: cellPath)
        }
        else {
            legendLabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: financialsFontSize)
                label.text = "Growth EMA:\nConsistency:"
                label.textAlignment = .right
                label.numberOfLines = 0
                label.sizeToFit()
                return label
            }()
            self.contentView.addSubview(legendLabel!)
            legendLabel!.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset-10).isActive = true
            legendLabel!.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            legendLabel!.leadingAnchor.constraint(greaterThanOrEqualTo: rowTitleLabel.trailingAnchor, constant: 10).isActive = true
            
            createFinancialsTexts(cellPath: cellPath)
        }
    }
    
    private func createLabels(cellPath: IndexPath) {
        
        let (strings, colors) = controller.rowTexts(forPath: cellPath)
        valueLabels = [UILabel]()
        labelBackgroundViews = [UIView]()

        var count: CGFloat = 0
        
        for string in strings {
            
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: financialsFontSize, weight: .bold)
//                label.font = UIFont.systemFont(ofSize: financialsFontSize)
//                label.textColor = colors[Int(count)]
                label.text = string
                label.numberOfLines = 0
                label.sizeToFit()
                return label
            }()
            
            let backgroundView: UIView = {
                let view = UIView()
                view.translatesAutoresizingMaskIntoConstraints = false
                view.backgroundColor = colors[Int(count)]
                return view
            }()
            self.contentView.addSubview(backgroundView)
            labelBackgroundViews?.append(backgroundView)
            
            self.contentView.addSubview(label)
            valueLabels?.append(label)

            backgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*count).isActive = true
            backgroundView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            backgroundView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
            backgroundView.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*(count+1)-5).isActive = true

            
            label.leadingAnchor.constraint(greaterThanOrEqualTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*count).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*(count+1)-20).isActive = true
            count += 1
        }
    }
    
    private func createTextView(cellPath: IndexPath) {
        
        let (strings,_) = controller.rowTexts(forPath: cellPath)
        textViews = [UITextView]()

        var count: CGFloat = 0
        
        for string in strings {
            
            let textView: UITextView = {
                let view = UITextView()
                view.translatesAutoresizingMaskIntoConstraints = false
                view.font = UIFont.systemFont(ofSize: 12)
                view.text = string
                view.sizeToFit()
                view.showsHorizontalScrollIndicator = false
                view.backgroundColor = contentView.backgroundColor
                return view
            }()
            self.contentView.addSubview(textView)
            textViews?.append(textView)
            
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth * count).isActive = true
            textView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            textView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
            textView.widthAnchor.constraint(equalToConstant: columnWidth-10).isActive = true
            count += 1
        }

    }
    
    private func chartsView(cellPath: IndexPath) {
        
        let (_, values) = controller.fundamentals(forPath: cellPath)
        
        var count: CGFloat = 0
        
        charts = [ValueChart]()
        valueLabels = [UILabel]()
        for array in values ?? [] {
            
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: financialsFontSize-2)
                label.text = " "
                label.numberOfLines = 0
                label.sizeToFit()
                return label
            }()
            contentView.addSubview(label)
            valueLabels?.append(label)
            
            let newChart = ValueChart()
            newChart.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(newChart)
            
            label.topAnchor.constraint(equalTo: topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth * count + 10).isActive = true
            label.widthAnchor.constraint(equalToConstant: columnWidth-10).isActive = true
            
            newChart.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth * count + 10).isActive = true
            newChart.topAnchor.constraint(equalTo: label.bottomAnchor,constant: 3).isActive = true
            newChart.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            newChart.widthAnchor.constraint(equalToConstant: columnWidth-10).isActive = true
            
            newChart.backgroundColor = UIColor.systemBackground
            let biggerIsBetter = (cellPath.section == 6) ? false : true
            newChart.configure(array: array, biggerIsBetter: biggerIsBetter ,trendLabel: label, longTitle: false ,valuesAreGrowth: true, showXLabels: false, showYLabels: true)
            charts?.append(newChart)
            count += 1
        }

    }
     
    private func createFinancialsTexts(cellPath: IndexPath) {
        
        guard let (texts, colors) = controller.financialsTexts(forPath: cellPath) else {
            return
        }
        valueLabels = [UILabel]()

        var count: CGFloat = 0
        
        for duplet in texts {
            
            guard duplet.count > 1 else {
                return
            }
                        
            let label: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 0
                label.font = UIFont.systemFont(ofSize: financialsFontSize, weight: .bold)
                label.text = duplet[0] + "\n" + duplet[1]
//                label.textColor = colors.first ?? UIColor.label
                label.textAlignment = .right
                label.sizeToFit()
                return label
            }()
            let backgroundView: UIView = {
                let view = UIView()
                view.translatesAutoresizingMaskIntoConstraints = false
                view.backgroundColor = colors[Int(count)]
                return view
            }()
            self.contentView.addSubview(backgroundView)
            labelBackgroundViews?.append(backgroundView)
            self.contentView.addSubview(label)
            valueLabels?.append(label)
            
            
            backgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*count).isActive = true
            backgroundView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
            backgroundView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
            backgroundView.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*(count+1)-5).isActive = true

            label.leadingAnchor.constraint(greaterThanOrEqualTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*count).isActive = true
            label.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: margins.leadingAnchor, constant: firstColumnInset + columnWidth*(count+1) - 20).isActive = true
            count += 1
        }
    }

}
