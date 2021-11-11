% NewRadio-TestModel and FRC Waveform Generation
% these are waveforms specified for testing ( in Documenation, standarized )
% use 5G Waveform Generator

lReferenceWaveformID = "NR-FR1-TM1.2";
lChannelBandwidth = "10MHz";
lSubcarrierSpacing = "15kHz";
lDuplexMode = "FDD";

% Waveform Object for specified NewRadio-TestModel reference WaveformID
lWaveformObject = hNRReferenceWaveformGenerator( lReferenceWaveformID, lChannelBandwidth, lSubcarrierSpacing, lDuplexMode );

lWaveformObject = makeConfigWritable(lWaveformObject);
lWaveformObject.Config.WindowingPercent = 0;

% Actual Waveform generation
[lWaveform, lWaveformInfo] = generateWaveform( lWaveformObject );

% Set sampling rate
lSamplingRate = lWaveformInfo.Info.SamplingRate;

% Data Visualisation - PRB and SC resource grid
% PRB physical resource block
% SC subcarrier

displayResourceGrid( lWaveformObject );

% Compute ACLR Parameters

lACLRParameters = hACLRParametersNR( lWaveformObject.Config );
disp( lACLRParameters );

% Filter design 

lLowPassFilter = designfilt( 'lowpassfir',...
    'PassbandFrequency',lACLRParameters.BandwidthConfig/2,...
    'StopbandFrequency',lACLRParameters.Bandwidth/2,...
    'PassbandRipple',0.1,...
    'StopbandAttenuation',80,...
    'SampleRate',lSamplingRate );
lFilteredWaveform = filter( lLowPassFilter, lWaveform );

% Oversampling and HPA Nonlinearity Model

lResampledWaveform = resample( lWaveform, lACLRParameters.OSR, 1 );
lResampledFilteredWaveform = resample ( lFilteredWaveform, lACLRParameters.OSR, 1 );

% Nonlinearity creation - amplifier modelling HPA ( High Power Amplifier )

lNonLinearity = comm.MemorylessNonlinearity;
lNonLinearity.Method = 'Rapp model';
lNonLinearity.Smoothness = 3;
lNonLinearity.LinearGain = 0.5; % in [dB]
lNonLinearity.OutputSaturationLevel = 2;

% Signal Condidioning - control HPA back-off level
lResampledWaveform = lResampledWaveform / max( abs(lResampledFilteredWaveform) );
lResampledFilteredWaveform = lResampledFilteredWaveform / max( abs(lResampledFilteredWaveform) );

% HPA Application to NR model Waveforms
lHPAWaveform = lNonLinearity( lResampledWaveform );
lHPAFilteredWaveform = lNonLinearity( lResampledFilteredWaveform );

% Calculate NR ACLR
lACLRResult = hACLRMeasurementNR( lACLRParameters, lHPAWaveform );  % NonFiltered
lACLRResultFiltered = hACLRMeasurementNR( lACLRParameters, lHPAFilteredWaveform ); % Filtered

% Calculate error vector Magnitude
evmCfg.PlotEVM = false;
evmCfg.SampleRate = lACLRParameters.SamplingRate;
evmCfg.Label = lWaveformObject.ConfiguredModel{1};

% Measure EVM related statistics

% this does not work so far
% evmInfo = hNRPDSCHEVM( lWaveformObject.Config, lHPAFilteredWaveform, evmCfg );

% Diplay results - plot NR Spectrum and Adjacent Channel Leakage ratios
hACLRResultsNR( lACLRResult, lHPAWaveform, '(not filtered waveform)' );
hACLRResultsNR( lACLRResultFiltered, lHPAFilteredWaveform, '( filtered waveform)' );
