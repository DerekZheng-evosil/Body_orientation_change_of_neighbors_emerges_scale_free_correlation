% ******************* ��ʾ�������˶�״̬ **********************
function analysisRobots_performance(G)
    dt = G.cycTime;

    % --------- �������ͳ���� ---------    
    heading = nan * zeros(G.simStep,G.maxID);
    speed = nan * zeros(G.simStep,G.maxID);
    rotRate = nan * zeros(G.simStep,G.maxID);
    flockpos = nan * zeros(G.simStep,2);
    respondness = nan * zeros(G.simStep,1);
    cnt = 0;
    for t = 1:G.simStep
        posDir = [];
        p_posDir = [];
        for i = 1:G.maxID
            heading(t,i) = vel2heading_deg(G.actor{i}.memory(t,[3,4]));
            posDir(i,[1,2,3,4]) = G.actor{i}.memory(t,[1,2,3,4]);
            if t>=2
                p_posDir(i,[1,2,3,4]) = G.actor{i}.memory(t-1,[1,2,3,4]);
                speed(t,i) = norm(posDir(i,[1,2])-p_posDir(i,[1,2]))/dt;
                rotRate(t,i) = acosd(dot(posDir(i,[3,4]),p_posDir(i,[3,4])))/dt;
            end
        end
        pos_tmp = posDir(:,[1,2])'./G.fishBL;
        dist_xy = squareform((pdist(pos_tmp(:,[1:G.expNum])','euclidean'))); 

        flockpos(t,:) = nanmean(posDir(:,[1,2]),1);

        if isfield(G,'infoIDs')
            if mod(t, G.activeTime) == 0
                cnt = cnt + 1;
                turnDir = G.turnDir_list(:,cnt);
                infoID = G.infoIDs_list(cnt);
%                 turnDir = G.actor{infoID}.memory(t,[3,4]);
            end
        end
        if t >= G.activeTime
            respondness(t,:) = (nansum(posDir(:,[3,4])',2)/G.num)' * [turnDir(1); turnDir(2)];
        else
            respondness(t,:) = 0;
        end

%         end
    end
    
    % --------- ��ͼ�������� ---------
    figure('posi',[100,200,1000,600]);   	% �����ھ��
    h_trajAxes = axes('Posi',[0.05 0.08 0.5 0.9]);    	% �����˹켣��ʾ
    xlim([-3000,3000]); ylim([-3000,3000]); 
    h_speedAxes = axes('Posi',[0.6 0.82 0.35 0.15]);    % ���������ٶ���ʾ 
    h_headingAxes = axes('Posi',[0.6 0.57 0.35 0.15]);	% �����˳�����ʾ 
    h_respondAxes = axes('Posi',[0.6 0.33 0.35 0.15]);	% �����˽��ٶ���ʾ      
    h_opAxes = axes('Posi',[0.6 0.08 0.35 0.15]);       % Ⱥ���������ʾ
    
    % ------------  ������ --------------
    % ���ƣ�������λ�á�heading���켣    
    r = 30;             % �����˰뾶mm
    arrow_scale = 30;   % ������heading
    axes(h_trajAxes); box on; grid on; axis equal; 
    for i = 1:G.maxID
        pos = G.actor{i}.pose;
        vel = G.actor{i}.vel;
        tailTraj = G.actor{i}.memory(:,[1,2]);
        if ~isnan(pos)
            % ��ʾ�������˶��켣
            quiver(pos(1),pos(2),arrow_scale*vel(1),arrow_scale*vel(2),0,'k','linewidth',1); hold on;
            line(tailTraj(2:end,1),tailTraj(2:end,2),'linestyle','-','linewidth',0.5); hold on;
            rectangle('Position', [pos(1)-r, pos(2)-r, r*2, r*2], 'Curvature', [1 1]); hold on;
        end
    end
    % ���ƣ�the informed traj.
    for k = 1:length(G.infoIDs_list)
        infoID = G.infoIDs_list(k);
        tailTraj = G.actor{infoID}.memory(:,[1,2]);
        line(tailTraj(2:end,1),tailTraj(2:end,2),'linestyle','-','linewidth',1,'color',[1,0,0]); hold on;
    end
    % ���ƣ�Ⱥ������
    line(flockpos(2:end,1),flockpos(2:end,2),'linestyle','-','linewidth',1.5,'color',[0,0,1]); hold on;
    % ���ƣ����ر߽�
    rectangle('Position', [-2790,-2890,5380, 5680], 'Curvature', [0 0],'linewidth',2); hold on;
    rectangle('Position', [-2100,-2350,4200, 4700], 'Curvature', [0 0],'linewidth',3,'edgecolor',[0,0,1]); hold on;
    % ���ƣ�����ĸ�֪��Χ��id=1��
    if isfield(G,'r_sense')
        pos = G.actor{1}.pose;
        r = G.r_sense;
        rectangle('Position', [pos(1)-r, pos(2)-r, r*2, r*2], 'Curvature', [1 1],'edgecolor',[0,1,0]); hold on;
    end
    box on; grid on; axis equal; 
    
    % ------------- �������� ------------
    % ��ʾ��op����
    axes(h_speedAxes);
    box on; grid on; xlabel('time/step'); ylabel('speed');
    h_speed = line([1:G.simStep],speed,'linestyle','-','linewidth',1); hold on;
    axes(h_opAxes); 
    box on; grid on; xlabel('time/step'); ylabel('op'); ylim([0,1]);
    h_op = line([1:G.simStep],G.op(1,:),'linestyle','-','linewidth',1); hold on;
    % ��ʾ��heading����
    axes(h_headingAxes);
    plot([1:G.simStep],heading); hold on;
    for k = 1:length(G.infoIDs_list)
        infoID = G.infoIDs_list(k);
        plot([G.activeTime + (k-1) * G.activeTime:G.activeTime + (k*G.activeTime) - 1], heading(G.activeTime + (k-1) * G.activeTime:G.activeTime + + (k*G.activeTime) - 1,infoID),'linewidth',1,'color',[1,0,0]); hold on;
    end
    xlabel('steps');
    ylabel('heading(deg)');
    % ��ʾ��respondness����
    axes(h_respondAxes);
    plot([1:G.simStep],respondness); hold on;
    xlabel('steps');
    ylabel('accuracy');
    title(['rsp=',num2str(mean(respondness(G.activeTime:end)))]);
end