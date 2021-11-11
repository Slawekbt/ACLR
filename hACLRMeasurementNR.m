%hACLRMeasurementNR NR ACLR measurement
%   ACLR = hACLRMeasurementNR(ACLR,RESAMPLED) measures the NR ACLR
%   of a waveform RESAMPLED given parameters in the structure ACLR.
%   Measurements are added to the parameter structure.

%   Copyright 2019 The MathWorks, Inc.

function aclr = hACLRMeasurementNR(aclr,resampled)

    % Calculate the DFT size Ndft that which will result in an integer
    % number of bins in the transmission bandwidth configuration
    % (BandwidthConfig).
    gcdBWConfig = gcd(aclr.SamplingRate,aclr.BandwidthConfig);
    Ndft = aclr.SamplingRate/gcdBWConfig;

    % Also ensure that Ndft is even
    multEvenNdft = 1+mod(Ndft,2);
    Ndft = Ndft*multEvenNdft;

    % Calculate NbinsConfig, the number of DFT bins which spans channel
    % transmission bandwidth configuration of interest.
    NbinsConfig = aclr.BandwidthConfig*multEvenNdft/gcdBWConfig;
    multEvenNbinsConfig = 1+mod(NbinsConfig,2);

    % Also ensure that NbinsConfig is even
    NbinsConfig = NbinsConfig*multEvenNbinsConfig;
    Ndft = Ndft*multEvenNbinsConfig;   

    % Increase the DFT size, if necessary, so that the frequency resolution
    % is a multiple of the subcarrier spacing.
    delta_f = aclr.SamplingRate/Ndft;
    multFreqRes = ceil(delta_f/aclr.SubcarrierSpacing);
    Ndft = Ndft*multFreqRes;    
    NbinsConfig = NbinsConfig*multFreqRes;

    % Calculate NbinsChannel, the number of DFT bins between adjacent
    % channel center frequencies, increasing the number of DFT bins if
    % necessary to make NbinsChannel an integer.
    gcdBW = gcd(aclr.SamplingRate,aclr.Bandwidth);
    NdftTemp = aclr.SamplingRate/gcdBW;
    multNbinsChannelInt = NdftTemp/gcd(Ndft,NdftTemp);
    Ndft = Ndft*multNbinsChannelInt;

    NbinsConfig = NbinsConfig*multNbinsChannelInt;
    NbinsChannel = aclr.Bandwidth*Ndft/aclr.SamplingRate;        

    % OFDM demodulate the measurement signal using the DFT.
    Ndfts = floor(size(resampled,1)/Ndft);
    dftinput = reshape(resampled(1:(Ndfts*Ndft)),Ndft,Ndfts);
    win = repmat(window(@blackmanharris,Ndft),1,Ndfts);
    win = win * sqrt(size(win,1)/sum(win(:,1).^2));
    demod = fftshift(fft(dftinput.*win,Ndft),1)/Ndft;       

    % For each channel index in the array [-2 -1 0 1 2] record the channel
    % center frequency and calculate the channel power by calculating the
    % energy in relevant DFT bins.
    powerdBm = zeros(1,5);
    for i = -2:2

        % Calculate energy in relevant DFT bins
        m = abs(demod((Ndft/2)+1+(i*NbinsChannel)+...
            (-(NbinsConfig/2):NbinsConfig/2),:).^2);                

        % Calculate power
        p = sum(m(:))/size(m,2);
        powerdBm(i+3) = 10*log10(p)+30;

        % Record center frequency
        aclr.CarrierFrequency(i+3) = i*NbinsChannel/Ndft*aclr.SamplingRate;

    end    

    % Calculate the ACLs by subtracting the channel power from the signal
    % power. Extract power of input signal as middle value i.e. channel = 0  
    aclr.SignalPowerdBm = powerdBm(3);

    % Subtracting channel power from input signal power
    aclr.ACLRdB = aclr.SignalPowerdBm-powerdBm;

    % Remove central element which corresponds to input signal
    aclr.ACLRdB(3) = [];
    aclr.CarrierFrequency(3) = [];

end
