// GraphView.swift
import UIKit
import DGCharts

class GraphView: UIView {
    // MARK: - Properties
    private let chartView = LineChartView()
    private var dataEntries: [ChartDataEntry] = []
    private let displayCount = 100 // Maximum number of points to display
    
    // Chart styling
    private let lineColor = UIColor.systemRed
    private let fillColor = UIColor.systemRed.withAlphaComponent(0.1)
    private let circleColor = UIColor.systemRed
    
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
        // Add chart view to hierarchy
        addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: topAnchor),
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
    
    // MARK: - Data Management
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
