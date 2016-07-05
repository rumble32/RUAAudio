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
    var mixerNo1UnitInfo: RUAAudoUnitInfo?

    var mixerNo2UnitInfo: RUAAudoUnitInfo?

    
    var sampleRate: Float64 = 44100.0;
    var inputFormat: AudioStreamBasicDescription?

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
        
        // Set up mixer No.1
        mixerNo1UnitInfo = setupAudioUnit(toGraph: audioGraph!, componentType: kAudioUnitType_Mixer, componentSubType:kAudioUnitSubType_MultiChannelMixer)
        
        // Set up mixer No.2
        mixerNo2UnitInfo = setupAudioUnit(toGraph: audioGraph!, componentType: kAudioUnitType_Mixer, componentSubType:kAudioUnitSubType_MultiChannelMixer)
    
        // Open the audioGraph
        status = AUGraphOpen(audioGraph!)
        
        // Obtain audiounit from node
        status = AUGraphNodeInfo(audioGraph!, ioUnitInfo!.node, nil, &(ioUnitInfo!.audioUnit))
        if (noErr != status) {
            print("AUGraphNodeInfo ioUnit status = \(status)")
        }
        
        status = AUGraphNodeInfo(audioGraph!, mixerNo1UnitInfo!.node, nil, &(mixerNo1UnitInfo!.audioUnit))
        if (noErr != status) {
            print("AUGraphNodeInfo mixerUnit1 status = \(status)")
        }
        
        status = AUGraphNodeInfo(audioGraph!, mixerNo2UnitInfo!.node, nil, &(mixerNo2UnitInfo!.audioUnit))
        if (noErr != status) {
            print("AUGraphNodeInfo mixerUnit2 status = \(status)")
        }
        
        // Set Property
        
        let inDataSize = UInt32(sizeof(UInt32))
        
        //enable input scope for remote IO unit
        var flag: UInt32 = 1;
        status = AudioUnitSetProperty(
                            ioUnitInfo!.audioUnit!,
                            kAudioOutputUnitProperty_EnableIO,
                            kAudioUnitScope_Input,
                            kIOUnitInputBus,
                            &flag,
                            inDataSize)
        
        // Setup inputFormat
        self.inputFormat = defaultInputFormat()
        let propSize = UInt32(sizeof(AudioStreamBasicDescription))
        status = AudioUnitSetProperty(
                            ioUnitInfo!.audioUnit!,
                            kAudioUnitProperty_StreamFormat,
                            kAudioUnitScope_Output,
                            kIOUnitInputBus,
                            &(self.inputFormat!),
                            propSize)
        

        //mixer No.1
        var mixerInputCount: UInt32 = 2
        status = AudioUnitSetProperty (
                    mixerNo1UnitInfo!.audioUnit!,
                    kAudioUnitProperty_ElementCount,
                    kAudioUnitScope_Input,
                    0,
                    &mixerInputCount,
                    inDataSize)
        
        
        var maximumFramesPerSlice: UInt32 = 4096;
        status = AudioUnitSetProperty (
                    mixerNo1UnitInfo!.audioUnit!,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &maximumFramesPerSlice,
                    inDataSize)
        
        //mixer No.2
        var mixer2InputCount: UInt32 = 2
        status = AudioUnitSetProperty (
                    mixerNo2UnitInfo!.audioUnit!,
                    kAudioUnitProperty_ElementCount,
                    kAudioUnitScope_Input,
                    0,
                    &mixer2InputCount,
                    inDataSize)
        
        status = AudioUnitSetProperty (
                    mixerNo2UnitInfo!.audioUnit!,
                    kAudioUnitProperty_MaximumFramesPerSlice,
                    kAudioUnitScope_Global,
                    0,
                    &maximumFramesPerSlice,
                    inDataSize)
        
        
        // Connect nodes of the audioGraph
        status = AUGraphConnectNodeInput(audioGraph!, ioUnitInfo!.node, kIOUnitInputBus, mixerNo1UnitInfo!.node, kMixerMicrophoneInputBus)
        
        //
        status = AUGraphConnectNodeInput(audioGraph!, mixerNo1UnitInfo!.node, 0, mixerNo2UnitInfo!.node, kMixerMicrophoneInputBus)
        
        //
        status = AUGraphConnectNodeInput(audioGraph!, mixerNo2UnitInfo!.node, 0, ioUnitInfo!.node, kIOUnitOutputBus)
        
        // Initialize the audio  graph, configure audio data stream formats for
        //    each input and output, and validate the connections between audio units.
        status = AUGraphInitialize (audioGraph!);
        if (noErr != status) {
            print("AUGraphInitialize status = \(status.description)")
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
    
    //
    func defaultInputFormat() -> AudioStreamBasicDescription {
        
        let floatByteSize: UInt32 = (UInt32)(sizeof(Float));

        let basicDescription = AudioStreamBasicDescription(mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved, mBytesPerPacket: floatByteSize, mFramesPerPacket: 1, mBytesPerFrame: floatByteSize, mChannelsPerFrame: 2, mBitsPerChannel: 8 * floatByteSize, mReserved: 0)
        
        return basicDescription
    }
}
