function API_CSI_MUSIC_Visualize( Xt, samples, paths, Nrx, ant_dist, fc, Nc, Delta_f)
Rxx = Xt*Xt'/samples;
[eigvec_mat, diag_mat_of_eigval] = eig(Rxx); % ����������������������ֵ�ԽǾ���
eigenvalues = diag(diag_mat_of_eigval);     % ȡ��������ֵ
[~,IndexVector] = sort(eigenvalues);        % ������ֵ�������򣬲�����index vector
eigvec_mat = fliplr(eigvec_mat(:,IndexVector));
% ���������������е���˳�򣬵���ԭ��Ϊ���������ֵ��Ӧ����������������
% ����������������ֵ���н������У�������ֵ����key����������������value

%% ����MUSICα��
aoa = -90:1:90;       % -90~90 [ns]
tof = (0:1:100)*1e-9; % 1~100 [ns]
Pmusic = zeros(length(aoa),length(tof));
for iAoA = 1:length(aoa)
    for iToF = 1:length(tof)
        a = util_steering_aoa_tof(aoa(iAoA),tof(iToF),Nrx,ant_dist,fc,Nc,Delta_f);            
        L = paths;  % ��Դ������
        En = eigvec_mat(:,L+1:Nrx*Nc);
        %Pmusic(iAoA,iToF) = abs(1/(a'*(En*En')*a));
        Pmusic(iAoA,iToF) = abs((a'*a)/(a'*(En*En')*a));
    end
end

LOG_DATE = strrep(datestr(now,30),'T','');

hMUSIC = figure('Name', 'MUSIC_AOA_TOF', 'NumberTitle', 'off');
[meshAoA,meshToF] = meshgrid(aoa,tof);
SPmax=max(max(Pmusic));
Pmusic=10*log10(Pmusic/SPmax);
mesh(meshAoA,meshToF*1e9,Pmusic');
axis([-90 90 0 100]);
xlabel('Angle of Arrival in degrees[deg]')
ylabel('Time of Flight[ns]')
zlabel('Spectrum Peaks[dB]')
title('AoA and ToF Estimation from Modified MUSIC Algorithm')
grid on; hold on;

fprintf('\nFind all peaks of MUSIC spectrum: \n');

global PLOT_MUSIC_AOA PLOT_MUSIC_TOF 
global SAVE_FIGURE
%% MUSIC_AOA���ӻ�
if PLOT_MUSIC_AOA
    num_computed_paths = paths;
    figure_name_string = sprintf('MUSIC_AOA, Number of Paths: %d', num_computed_paths);
    figure('Name', figure_name_string, 'NumberTitle', 'off')

    PmusicEnvelope_AOA = zeros(length(aoa),1);
    for i = 1:length(aoa)
        PmusicEnvelope_AOA(i) = max(Pmusic(i,:));
    end

    plot(aoa, PmusicEnvelope_AOA, '-k')
    xlabel('Angle, \theta[deg]')
    ylabel('Spectrum function P(\theta, \tau)  / dB')
    title('AoA Estimation')
    grid on;grid minor;hold on;

   %% ��������·����AoA
    % ���򷵻�ǰpaths��ķ�ֵ��������
    [pktaoa,lctaoa]  = findpeaks(PmusicEnvelope_AOA,'SortStr','descend','NPeaks',paths); 
    % ��Ƿ�ֵ
    plot(aoa(lctaoa),pktaoa,'o','MarkerSize',12);
    % ���������ֵ������
    disp(['Calculated AoA: ' num2str(sort(round(aoa(lctaoa)),'ascend')) ' [deg]'] )
    
    if SAVE_FIGURE
        figureName = ['./figure/' LOG_DATE '_' 'MUSIC_AOA' '.jpg'];
        saveas(gcf,figureName);
    end
end

%% MUSIC_TOF���ӻ�
if PLOT_MUSIC_TOF
    if Nc ~= 1
        num_computed_paths = paths;
        figure_name_string = sprintf('MUSIC_TOF, %d paths', num_computed_paths);
        figure('Name', figure_name_string, 'NumberTitle', 'off')

        PmusicEnvelope_ToF = zeros(length(tof),1);
        for i = 1:length(tof)
            PmusicEnvelope_ToF(i) = max(Pmusic(:,i));
        end

        plot(tof*1e9, PmusicEnvelope_ToF, '-k')
        xlabel('ToF, \tau[ns]')
        ylabel('Spectrum function P(\theta, \tau)  / dB')
        title('ToF Estimation')
        grid on;grid minor;hold on;
       %% ��������·����ToF
        [pkttof,lcttof]  = findpeaks(PmusicEnvelope_ToF,'SortStr','descend','NPeaks',paths); % 'MinPeakHeight',-4
		plot(tof(lcttof)*1e9, pkttof,'o','MarkerSize',12)
		disp(['Calculated ToF: ' num2str(sort(round(tof(lcttof)*1e9),'ascend')) ' [ns]'] );

        if SAVE_FIGURE
            figureName = ['./figure/' LOG_DATE '_' 'MUSIC_TOF' '.jpg'];
            saveas(gcf,figureName);
        end

       %% ����ֱ�侶AoA��ToF
    fprintf('\nFind Direct Path AoA and ToF: \n')
    direct_path_tof_index = find(tof == tof(min(lcttof)));
	% ������PmusicEnvelope_ToF findpeaks�ĵ�һ����ֵ��index�� ������
    direct_path_tof = tof(min(lcttof))*1e9; % ��λ�� ns
	
    [~,direct_path_aoa_index] = max(Pmusic(:,direct_path_tof_index));
    direct_path_aoa = aoa(direct_path_aoa_index);
	% ����tof����Сֵ��ȷ��ΪLOS
    disp(['(AOA, ToF) =  ('  num2str(direct_path_aoa) ' [deg], '  ...
       num2str(direct_path_tof) ' [ns]) ']);

   %% ��MUSICα���б��ֱ�侶
    % set(groot,'CurrentFigure',hMUSIC);hold on;
    x_aoa = direct_path_aoa;
    y_tof = direct_path_tof;
    z_dB = Pmusic(direct_path_aoa_index,direct_path_tof_index);
	currentAxis = get(hMUSIC, 'CurrentAxes');
   % plot3(currentAxis, x_aoa,y_tof,z_dB,'o','MarkerSize',12);
	scatter3(currentAxis, x_aoa, y_tof, z_dB, 'filled', 'MarkerEdgeColor','r');
	
    txt = sprintf('Direct Path: \n( %d[deg], %d[ns])', ...
        round(direct_path_aoa), ...
        round(direct_path_tof));
     text(currentAxis, x_aoa,y_tof,txt);
	
    % ����figure hMUSICΪ��ǰ��ͼ

    figure(hMUSIC);
    view(-60,30);
    
    if SAVE_FIGURE
        figureName = ['./figure/' LOG_DATE '_' 'MUSIC_AOA_TOF' '.jpg'];
        saveas(gcf,figureName);
    end
end
end

