// GraphView.swift
import UIKit
import DGCharts

class GraphView: UIView {
    // MARK: - Properties
    private let chartView = LineChartView()
    private let titleLabel = UILabel()
    private var dataEntries: [ChartDataEntry] = []
    private let displayCount = 100 // Maximum number of points to display
    
    // Chart styling
    private var lineColor = UIColor.systemRed
    private var fillColor = UIColor.systemRed.withAlphaComponent(0.1)
    private var circleColor = UIColor.systemRed
    
    // Set to true for voltage1, false for voltage0
    private var isSecondaryGraph = false
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChart()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupChart()
    }
    
    // MARK: - Setup
    private func setupChart() {
        // Setup title label
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Add chart view to hierarchy
        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            chartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Configure chart appearance
        chartView.backgroundColor = UIColor.systemBackground
        chartView.rightAxis.enabled = false
        
        // Configure left axis (y-axis)
        let leftAxis = chartView.leftAxis
        leftAxis.labelFont = UIFont.systemFont(ofSize: 10)
        leftAxis.setLabelCount(6, force: false)
        leftAxis.labelTextColor = UIColor.label
        leftAxis.axisLineColor = UIColor.label
        leftAxis.gridColor = UIColor.secondarySystemFill
        
        // Configure x-axis
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 10)
        xAxis.setLabelCount(6, force: false)
        xAxis.labelTextColor = UIColor.label
        xAxis.axisLineColor = UIColor.label
        xAxis.gridColor = UIColor.secondarySystemFill
        
        // Initialize empty chart data
        updateChartData()
        
        // Disable legend
        chartView.legend.enabled = false
        
        // Enable chart interaction
        chartView.pinchZoomEnabled = true
        chartView.doubleTapToZoomEnabled = true
        chartView.dragEnabled = true
        chartView.dragXEnabled = true
        
        // Description text
        chartView.chartDescription.enabled = false
    }
    
    // Set the title for this graph and configure appearance
    func setTitle(_ title: String, isSecondaryGraph: Bool = false) {
        titleLabel.text = title
        self.isSecondaryGraph = isSecondaryGraph
        
        // Set different colors based on which graph this is
        if isSecondaryGraph {
            lineColor = UIColor.systemBlue
            fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
            circleColor = UIColor.systemBlue
        } else {
            lineColor = UIColor.systemRed
            fillColor = UIColor.systemRed.withAlphaComponent(0.1)
            circleColor = UIColor.systemRed
        }
        
        // Update chart data with new colors if data already exists
        if let chartData = chartView.data,
           let dataSet = chartData.dataSets.first as? LineChartDataSet {
            dataSet.colors = [lineColor]
            dataSet.setCircleColor(circleColor)
            dataSet.fillColor = fillColor
            chartData.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
    
    // MARK: - Data Management
    func updateChartData() {
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "Sensor Data")
        
        // Style the line
        chartDataSet.colors = [lineColor]
        chartDataSet.lineWidth = 2
        chartDataSet.setCircleColor(circleColor)
        chartDataSet.circleRadius = 3
        chartDataSet.circleHoleRadius = 2
        chartDataSet.fillColor = fillColor
        chartDataSet.mode = .cubicBezier
        chartDataSet.drawValuesEnabled = false
        chartDataSet.fillAlpha = 0.8
        chartDataSet.drawFilledEnabled = true
        
        // Set data to chart
        let chartData = LineChartData(dataSet: chartDataSet)
        chartView.data = chartData
        
        // Animate - only animate when initially setting up the chart
        if dataEntries.count <= 1 {
            chartView.animate(xAxisDuration: 0.3)
        }
    }
    
    func addDataPoint(_ value: Double) {
        // Create a ChartDataEntry with the current x-value
        let nextIndex = dataEntries.count > 0 ? dataEntries[dataEntries.count - 1].x + 1 : 0
        let entry = ChartDataEntry(x: nextIndex, y: value)
        
        // Add to data entries
        dataEntries.append(entry)
        
        // Limit number of visible points by removing the first entry if needed
        if dataEntries.count > displayCount {
            dataEntries.removeFirst()
            
            // Update the visible x-axis range to create a scrolling effect
            let minX = dataEntries.first?.x ?? 0
            let maxX = dataEntries.last?.x ?? 0
            chartView.xAxis.axisMinimum = minX
            chartView.xAxis.axisMaximum = maxX
        }
        
        // Instead of recreating the dataset, update the existing one
        if let chartData = chartView.data,
           let dataSet = chartData.dataSets.first as? LineChartDataSet {
            // Update the existing dataset
            dataSet.replaceEntries(dataEntries)
            
            // Notify chart that data has changed
            chartData.notifyDataChanged()
            chartView.notifyDataSetChanged()
            
            // Only request a partial redraw
            chartView.setNeedsDisplay()
        } else {
            // If no dataset exists yet, create one (first time)
            updateChartData()
        }
    }
    
    func clearData() {
        dataEntries.removeAll()
        updateChartData()
    }
}
