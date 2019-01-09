//
//  WeekAvailabilityController.swift
//  Lattice
//
//  Created by Eli Zhang on 12/31/18.
//  Copyright © 2018 Eli Zhang. All rights reserved.
//

import UIKit
import SnapKit

class BlockCalendarController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, DropDownData {
    
    var radialGradient: RadialGradientView!
    var verticalSwipe: UIPanGestureRecognizer!
    var tap: UITapGestureRecognizer!
    var backButton: UIButton!
    var blockCalendarLabel: UILabel!
    var intervalDropDown: DropDownButton!
    var separator: UIView!
    var fromLabel: UILabel!
    var fromDropDown: DropDownButton!
    var toLabel: UILabel!
    var toDropDown: DropDownButton!
    var dailyTimes: UIStackView!
    var collectionView: UICollectionView!
    var cellStates: [[CellSelectedState]]!

    let timeCellReuseIdentifier = "timeCell"
    let headerCellReuseIdentifier = "header"
    let dateFormatter = DateFormatter()
    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var slotsPerHour: Int = 2
    var startingHour: Int = 0
    var fromTime: String {
        if startingHour == 0 { return "12:00 am"}
        return "\(startingHour <= 12 ? startingHour : startingHour - 12):00 \(startingHour <= 12 ? "am" : "pm")"
    }
    var endingHour: Int = 23
    var toTime: String {
        if endingHour == 0 { return "12:00 am"}
        return "\(endingHour <= 12 ? endingHour : endingHour - 12):00 \(endingHour <= 12 ? "am" : "pm")"
    }
    var numTimeCells: Int {
        return (endingHour - startingHour + 1) * slotsPerHour
    }
    let headerCellHeight: CGFloat = 30

    override func viewDidLoad() {
        view.backgroundColor = .black
        radialGradient = RadialGradientView()
        view.addSubview(radialGradient)
        
        backButton = UIButton()
        backButton.setImage(UIImage(named: "BackArrow")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.imageView?.tintColor = Colors.labelColor
        backButton.addTarget(self, action: #selector(popView), for: .touchUpInside)
        view.addSubview(backButton)
        
        blockCalendarLabel = UILabel()
        blockCalendarLabel.text = "Block times"
        blockCalendarLabel.textColor = Colors.labelColor
        blockCalendarLabel.font = UIFont(name: "Nunito-Regular", size: 30)
        view.addSubview(blockCalendarLabel)
        
        intervalDropDown = DropDownButton()
        intervalDropDown.dropView.dropDownOptions = ["Every hour", "Every half hour"]
        view.addSubview(intervalDropDown)
        
        fromLabel = UILabel()
        fromLabel.text = "From"
        fromLabel.textColor = Colors.labelColor
        fromLabel.font = UIFont(name: "Nunito-Light", size: 18)
        view.addSubview(fromLabel)
        
        fromDropDown = DropDownButton()
        fromDropDown.setTitle(fromTime, for: .normal)
        fromDropDown.dropView.dropDownOptions = ["12:00 am", "1:00 am", "2:00 am", "3:00 am", "4:00 am", "5:00 am", "6:00 am", "7:00 am", "8:00 am", "9:00 am", "10:00 am", "11:00 am", "12:00 pm", "1:00 pm", "2:00 pm", "3:00 pm", "4:00 pm", "5:00 pm", "6:00 pm", "7:00 pm", "8:00 pm", "9:00 pm", "10:00 pm", "11:00 pm", "12:00 pm"]
        fromDropDown.delegate = self
        view.addSubview(fromDropDown)
        
        toLabel = UILabel()
        toLabel.text = "to"
        toLabel.textColor = Colors.labelColor
        toLabel.font = UIFont(name: "Nunito-Light", size: 18)
        view.addSubview(toLabel)
        
        toDropDown = DropDownButton()
        toDropDown.setTitle(toTime, for: .normal)
        toDropDown.dropView.dropDownOptions = ["12:00 am", "1:00 am", "2:00 am", "3:00 am", "4:00 am", "5:00 am", "6:00 am", "7:00 am", "8:00 am", "9:00 am", "10:00 am", "11:00 am", "12:00 pm", "1:00 pm", "2:00 pm", "3:00 pm", "4:00 pm", "5:00 pm", "6:00 pm", "7:00 pm", "8:00 pm", "9:00 pm", "10:00 pm", "11:00 pm", "12:00 pm"]
        toDropDown.delegate = self
        view.addSubview(toDropDown)
        
        dailyTimes = UIStackView()
        dailyTimes.axis = .vertical
        dailyTimes.distribution = .fillEqually
        if startingHour < endingHour {
            for hour in startingHour...endingHour {
                for minute in 0..<slotsPerHour {
                    let timeLabel = UILabel()
                    timeLabel.text = "\(hour == 0 ? 12 : hour <= 12 ? hour : hour - 12):\(String(format: "%02d", 60 / slotsPerHour * minute)) \(hour <= 12 ? "am" : "pm")"
                    timeLabel.font = UIFont(name: "Nunito-Semibold", size: 15)
                    timeLabel.textColor = Colors.labelColor
                    if minute != 0 {
                        timeLabel.textColor = .clear
                    }
                    dailyTimes.addArrangedSubview(timeLabel)
                }
            }
        }
        view.addSubview(dailyTimes)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: timeCellReuseIdentifier)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: headerCellReuseIdentifier)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView)
        
        verticalSwipe = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        verticalSwipe.delegate = self
        collectionView.addGestureRecognizer(verticalSwipe)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        
        cellStates = [[CellSelectedState]]()
        for section in 0..<collectionView.numberOfSections {
            cellStates.append([CellSelectedState]())
            for _ in 0..<collectionView.numberOfItems(inSection: section) {
                cellStates[section].append(CellSelectedState(isSelected: false))
            }
        }
        setupConstraints()
    }
    
    func setupConstraints() {
        radialGradient.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        backButton.snp.makeConstraints { (make) -> Void in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.height.width.equalTo(25)
        }
        blockCalendarLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(35)
            make.trailing.equalTo(view).offset(-30)
            make.height.equalTo(30)
        }
        fromLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(blockCalendarLabel)
            make.top.equalTo(blockCalendarLabel.snp.bottom).offset(10)
            make.height.equalTo(40)
        }
        fromDropDown.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(fromLabel.snp.trailing)
            make.top.equalTo(fromLabel)
            make.height.equalTo(40)
            make.width.equalTo(120)
        }
        toLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(fromDropDown.snp.trailing)
            make.top.equalTo(fromLabel)
            make.height.equalTo(40)
        }
        toDropDown.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(toLabel.snp.trailing)
            make.top.equalTo(fromLabel)
            make.height.equalTo(40)
            make.width.equalTo(120)
        }
        dailyTimes.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(collectionView).offset(headerCellHeight)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20 - MenuBarParameters.menuBarHeight)
        }
        collectionView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(fromLabel.snp.bottom).offset(10)
            make.leading.equalTo(dailyTimes.snp.trailing).offset(10)
            make.trailing.equalTo(view).offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20 - MenuBarParameters.menuBarHeight)
        }
    }
    
    func createStackView() {
        for subview in dailyTimes.subviews {
            subview.removeFromSuperview()
        }
        if startingHour < endingHour {
            for hour in startingHour...endingHour {
                for minute in 0..<slotsPerHour {
                    let timeLabel = UILabel()
                    timeLabel.text = "\(hour <= 12 ? hour : hour - 12):\(String(format: "%02d", 60 / slotsPerHour * minute)) \(hour <= 12 ? "am" : "pm")"
                    timeLabel.font = UIFont(name: "Nunito-Semibold", size: 15)
                    timeLabel.textColor = Colors.labelColor
                    timeLabel.lineBreakMode = .byClipping
                    if minute != 0 {
                        timeLabel.textColor = .clear
                    }
                    dailyTimes.addArrangedSubview(timeLabel)
                }
            }
        }
        dailyTimes.setNeedsDisplay()
    }
    
    func itemSelected(sender: DropDownButton, contents: String) {
        if sender == fromDropDown {
            if contents == "12:00 am" {
                startingHour = 0
                return
            }
            startingHour = Int(contents.components(separatedBy: ":").first!) ?? startingHour
            if contents.suffix(2) == "pm" {
                startingHour += 12
            }
        }
        else if sender == toDropDown {
            if contents == "12:00 am" {
                startingHour = 0
                return
            }
            endingHour = Int(contents.components(separatedBy: ":").first!) ?? endingHour
            if contents.suffix(2) == "pm" {
                endingHour += 12
            }
        }
        createStackView()
        collectionView.reloadData()
    }
    
    @objc func handlePan() {
        if verticalSwipe.state == UIGestureRecognizer.State.began {
            // Shouldn't do anything because it may be scrolling
        }
        else if verticalSwipe.state == UIGestureRecognizer.State.changed {
            if abs(verticalSwipe.velocity(in: collectionView).x) < 100 {
                if let indexPath = collectionView.indexPathForItem(at: verticalSwipe.location(in: collectionView)) {
                    if indexPath.item == 0 {
                        return
                    }
                    let timeCell = collectionView.cellForItem(at: indexPath)
                    if !cellStates[indexPath.section][indexPath.item].isSelected {
                        timeCell?.backgroundColor = Colors.highlightedCell
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cellStates[indexPath.section][indexPath.item].isSelected = true
                        }
                    }
                    else {
                        timeCell?.backgroundColor = .clear
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cellStates[indexPath.section][indexPath.item].isSelected = false
                        }
                    }
                }
            }
        } else {
            if abs(verticalSwipe.velocity(in: collectionView).x) < 100 {
                if let indexPath = collectionView.indexPathForItem(at: verticalSwipe.location(in: collectionView)) {
                    if indexPath.item == 0 {
                        return
                    }
                    let timeCell = collectionView.cellForItem(at: indexPath)
                    if !cellStates[indexPath.section][indexPath.item].isSelected {
                        timeCell?.backgroundColor = Colors.highlightedCell
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cellStates[indexPath.section][indexPath.item].isSelected = true
                        }
                    }
                    else {
                        timeCell?.backgroundColor = .clear
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.cellStates[indexPath.section][indexPath.item].isSelected = false
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleTap() {
        if let indexPath = collectionView.indexPathForItem(at: tap.location(in: collectionView)) {
            if indexPath.item == 0 {
                return
            }
            let timeCell = collectionView.cellForItem(at: indexPath)
            if !cellStates[indexPath.section][indexPath.item].isSelected {
                timeCell?.backgroundColor = Colors.highlightedCell
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.cellStates[indexPath.section][indexPath.item].isSelected = true
                }
            }
            else {
                timeCell?.backgroundColor = .clear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.cellStates[indexPath.section][indexPath.item].isSelected = false
                }
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 7
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numTimeCells + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {    // Day name header
            return CGSize(width: collectionView.frame.width, height: headerCellHeight)
        }
        else {
            return CGSize(width: collectionView.frame.width, height: (collectionView.frame.height - headerCellHeight - 0.01) / CGFloat(numTimeCells))   // Must subtract a small amount due to round-off problems
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let customCell = cell as! HeaderCell
            customCell.configure(day: dayNames[indexPath.section])
            customCell.backgroundColor = Colors.blue
            customCell.setNeedsUpdateConstraints()
            customCell.layer.borderColor = Colors.infoBox.cgColor
            customCell.layer.borderWidth = 1
        }
        else {
            if cellStates[indexPath.section][indexPath.item].isSelected {
                cell.backgroundColor = Colors.highlightedCell
            }
            else {
                cell.backgroundColor = .clear
            }
            cell.layer.borderColor = Colors.infoBox.cgColor
            cell.layer.borderWidth = 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: headerCellReuseIdentifier, for: indexPath) as! HeaderCell
            cell.configure(day: dayNames[indexPath.section])
            cell.backgroundColor = Colors.blue
            cell.setNeedsUpdateConstraints()
            cell.layer.borderColor = Colors.infoBox.cgColor
            cell.layer.borderWidth = 1
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: timeCellReuseIdentifier, for: indexPath)
            if cellStates[indexPath.section][indexPath.item].isSelected {
                cell.backgroundColor = Colors.highlightedCell
            }
            else {
                cell.backgroundColor = .clear
            }
            cell.layer.borderColor = Colors.infoBox.cgColor
            cell.layer.borderWidth = 1
            return cell
        }
    }
    
    @objc func popView() {
        navigationController?.popViewController(animated: true)
    }
}

struct CellSelectedState {
    var isSelected: Bool // selection state
}

