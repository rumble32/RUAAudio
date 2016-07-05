//
//  RUAGraph.swift
//  RUAAudioDemo
//
//  Created by mol on 16/7/4.
//  Copyright © 2016年 rua. All rights reserved.
//

import AudioToolbox

struct RUAAudoUnitInfo {
    var audioUnit: AudioUnit?
    var node: AUNode = AUNode()
    var unitDescription: AudioComponentDescription?

}

// I/O unit bus
let kIOUnitInputBus: UInt32 = 1;
let kIOUnitOutputBus: UInt32 = 0;

//
let kMixerMicrophoneInputBus: UInt32 = 0;
let kMixerBgOneInputBus: UInt32 = 1;


class RUAGraph: NSObject {

    var audioGraph: AUGraph?
    
    var ioUnitInfo: RUAAudoUnitInfo?
    var mixerUnitInfo: RUAAudoUnitInfo?


    override init() {
        super.init()
        
        commonInit()
    }
    
    func commonInit() -> Void {
        
        // New Graph
        var status = NewAUGraph(&audioGraph)
        
        if (noErr != status) {
            print("NewAUGraph status = \(status)")
        }
        
        // Set up io
        ioUnitInfo = setupAudioUnit(toGraph: audioGraph!, componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_VoiceProcessingIO)
        
        // Set up mixer
        mixerUnitInfo = setupAudioUnit(toGraph: audioGraph!, componentType: kAudioUnitType_Mixer, componentSubType:kAudioUnitSubType_MultiChannelMixer)
        
    
        // Open the audioGraph
        status = AUGraphOpen(audioGraph!)
        
        // Obtain audiounit from node
        status = AUGraphNodeInfo(audioGraph!, ioUnitInfo!.node, nil, &(ioUnitInfo!.audioUnit))
        if (noErr != status) {
            print("AUGraphNodeInfo ioUnit status = \(status)")
        }
        
        status = AUGraphNodeInfo(audioGraph!, mixerUnitInfo!.node, nil, &(mixerUnitInfo!.audioUnit))
        if (noErr != status) {
            print("AUGraphNodeInfo mixerUnit status = \(status)")
        }
        
        // Set Property
        
        //mixer
        var mixerInputCount: UInt32 = 1
        let inDataSize = UInt32(sizeof(UInt32))
            
        status = AudioUnitSetProperty (mixerUnitInfo!.audioUnit!,
            kAudioUnitProperty_ElementCount,
            kAudioUnitScope_Input,
            0,
            &mixerInputCount,
            inDataSize
        );
        

        
        
        // Connect nodes of the audioGraph
        status = AUGraphConnectNodeInput(audioGraph!, ioUnitInfo!.node, kIOUnitInputBus, mixerUnitInfo!.node, kMixerMicrophoneInputBus)
        
        //
        status = AUGraphConnectNodeInput(audioGraph!, mixerUnitInfo!.node, 0, ioUnitInfo!.node, kIOUnitOutputBus)
        
        
        // Initialize the audio  graph, configure audio data stream formats for
        //    each input and output, and validate the connections between audio units.
        status = AUGraphInitialize (audioGraph!);
        if (noErr != status) {
            print("AUGraphInitialize status = \(status)")
        }
        
        //
        status = AUGraphStart(audioGraph!);
        if (noErr != status) {
            print("AUGraphStart status = \(status)")
        }
    }
    
    //MARK: Set up audio unit
    func setupAudioUnit(toGraph graph: AUGraph, componentType: OSType, componentSubType: OSType) -> RUAAudoUnitInfo {
        
        var node: AUNode = AUNode()
        var audioUnitInfo = RUAAudoUnitInfo()
        
        var unitDescription = AudioComponentDescription(componentType: componentType, componentSubType: componentSubType, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)

        let status = AUGraphAddNode(graph, &unitDescription, &node)
        if (noErr != status) {
            print("AUGraphAddNode \(componentType) status = \(status)")
        }
        
        
        audioUnitInfo.node = node
        audioUnitInfo.unitDescription = unitDescription
        
        
        return audioUnitInfo
    }
}
