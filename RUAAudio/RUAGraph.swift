//
//  RUAGraph.swift
//  RUAAudioDemo
//
//  Created by mol on 16/7/4.
//  Copyright © 2016年 rua. All rights reserved.
//

import UIKit
import AudioToolbox

struct RUAAudoUnitInfo {
    var audioUnit: AudioUnit?
    var node: AUNode = AUNode()
}

class RUAGraph: NSObject {

    var audioGraph: AUGraph?
    
    var microphoneUnitInfo: RUAAudoUnitInfo?
    var mixerUnitInfo: RUAAudoUnitInfo?

    var outputUnitInfo: RUAAudoUnitInfo?

    convenience override init() {
        self.init()
        
        
    }
    
    func commonInit() -> Void {
        
        //New Graph
        NewAUGraph(&audioGraph)
        
        self.mixerUnitInfo = self.setupMixerUnit(toGraph: audioGraph!)
        
        
    }
    
    //MARK: set up audio unit
    
    func setupMixerUnit(toGraph graph: AUGraph) -> RUAAudoUnitInfo {
        
        var node: AUNode = AUNode()
        var audioUnit: AudioUnit?
        var audioUnitInfo = RUAAudoUnitInfo()
        
        var mixerDescription = AudioComponentDescription(componentType: kAudioUnitType_Mixer, componentSubType: kAudioUnitSubType_MultiChannelMixer, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)

        AUGraphAddNode(graph, &mixerDescription, &node)
        
        AUGraphNodeInfo(graph, node, &mixerDescription, &audioUnit)
        
        audioUnitInfo.audioUnit = audioUnit
        audioUnitInfo.node = node
        
        return audioUnitInfo
    }
}
