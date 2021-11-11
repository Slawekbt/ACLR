%hACLRResultsNR NR ACLR measurement results
%   hACLRResultsNR(ACLR) displays NR ACLR measurement results and plots the
%   ACLR.

%   Copyright 2019 The MathWorks, Inc.

function hACLRResultsNR(aclr, waveform, arg)

    minACLR = 45;

    if nargin > 2
        titleText = [' ' arg];
    elseif nargin > 1
        titleText = [];
    else
        titleText = [];
        waveform = [];
    end
            
    disp(aclr);
    
    values = round([aclr.ACLRdB(1:end/2) 0 aclr.ACLRdB(end/2+1:end)],1);
    tick = 1:numel(values);
    ticklabel = tick-ceil(numel(tick)/2);
    labelvec = tick;
    labelvec(ceil(end/2)) = []; % Do not plot label for 0dB ACLR on channel
    
    % Plot NR Spectrum
    if ~isempty(waveform)
        figure;
        [spectrum, frequency] = pwelch(waveform, kaiser(8192*4,19), [], [], ...
            aclr.SamplingRate, 'centered', 'power');
        frequency = frequency * 10^(-6); % MHz
        spectrum = 10*log10(spectrum / max(spectrum));
        adjacentChannelLabel = [ticklabel(1:floor(length(ticklabel)/2)) ... 
        ticklabel(floor(length(ticklabel)/2)+2:end)];
        % Select 'x' and 'y' limits to show the adjacent channels in the plot
        xLimitRight = aclr.CarrierFrequency + (aclr.BandwidthConfig/2);
        xLimitRight = xLimitRight * 10^(-6); % MHz
        xLimitLeft = aclr.CarrierFrequency - (aclr.BandwidthConfig/2);
        xLimitLeft = xLimitLeft * 10^(-6); % MHz
        yLimits = [min(spectrum)-20 max(spectrum)+10];
        ylim(yLimits);
        xlim([min(frequency) max(frequency)])
        hold on; 
        for i = 1:length(aclr.CarrierFrequency)
            patch('XData',[xLimitRight(i) xLimitRight(i) xLimitLeft(i) ...
                xLimitLeft(i)],'YData', [yLimits fliplr(yLimits)], ...
                'FaceColor','y','FaceAlpha',0.2) % Plot adjacent channels
            text(aclr.CarrierFrequency(i)*10^(-6), i, sprintf('%d', ...
                adjacentChannelLabel(i)), 'HorizontalAlignment', 'Center', ...
                'VerticalAlignment', 'Top'); % Plot adjacent channel labels
        end
        plot(frequency, spectrum);
        hold off;
        xlabel('Frequency (MHz)');
        ylabel('Normalized Power (dB)');
        title(strcat ('NR Spectrum', titleText));
        legend('Adjacent channels', 'Location', 'SouthEast')
    end
    
    % Plot NR ACLR    
    figure;
    hold on;
    yline(minACLR,'r'); 
    bar(values, 'BaseValue', 0, 'FaceColor', 'yellow');
    hold off;
    set(gca, 'XTick', tick, 'XTickLabel', ticklabel, 'YLim', ... 
        [0 0.2*max(values)+max(values)]);
    for i = labelvec
        text(i, values(i), sprintf('%0.1f dB',values(i)), ...
            'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Top');
    end
    title(strcat('NR Adjacent Channel Leakage Ratio', titleText));
    xlabel('Adjacent Channel Offset');
    ylabel('Adjacent Channel Leakage Ratio (dB)');
    legend('Minimum required ACLR');
    
end