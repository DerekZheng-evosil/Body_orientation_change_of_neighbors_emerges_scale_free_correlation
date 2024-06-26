function [mean_acc, r_area, resp_time] = replay_collective_turn_snapshots(folder_name,plot_figure, activateTime, freq)

txtFiles = dir(folder_name);
G = struct;
G.cycTime = 1;
G.BL = 0.06; % meter
for i = 2:length(txtFiles)
    param = split(txtFiles(i).name, '_');
    if param{1} == "simData"
        robotId = str2double(erase(param{2}, ".txt")) + 1;
        G.actor{robotId}.memory = load([folder_name + '/' + txtFiles(i).name]);
    end
end
G.num = length(G.actor);
for i = 1:G.num
    len = size(G.actor{i}.memory,1);
    savingData(1:len,i,1:2)=G.actor{i}.memory(:,1:2)./ G.BL;
    savingData(1:len,i,3) = cos(G.actor{i}.memory(:,3) - pi/2);
    savingData(1:len,i,4) = sin(G.actor{i}.memory(:,3) - pi/2);
end

G.Drep = 150;
G.expNum = G.num;
G.total_step = size(savingData,1);

all_pos = [];
all_vel = [];
op = [];
nnd = [];

turning_period = round((size(savingData,1) - activateTime) / (freq * 2));
half_turning_period = round(turning_period/2);
turning_act_list = [];
turning_act_list(1) = activateTime + half_turning_period;
for k = 2:((freq * 2) + 1)
    turning_act_list(k) = turning_act_list(k-1) + turning_period;
end
turning_act_list(end) = size(savingData,1);

activate_time = activateTime;
r_acc = zeros(1, size(savingData,1));
informed_r_acc = zeros(1, size(savingData,1));
informed_id_file = load([folder_name + '/' + "informed_id.txt"]);
informed_id = informed_id_file(:,1);
resp_file = load([folder_name + '/' + 'informed_' + num2str(informed_id) + '_velocity.txt']);
resp_dir = resp_file';
informed_id = informed_id + 1; % python 中 index 从0开始


for t = 1:size(savingData,1)
    G.robotsPosH = squeeze(savingData(t,:,1:4));
    all_pos = G.robotsPosH(1:G.expNum, [1:2])';
    all_vel = G.robotsPosH(1:G.expNum, [3:4])';
    informed_vel(:,t) = all_vel(:,informed_id);
end

for t = 1:size(savingData,1)
    G.robotsPosH = squeeze(savingData(t,:,1:4));
    all_pos = G.robotsPosH(1:G.expNum, [1:2])';
    all_vel = G.robotsPosH(1:G.expNum, [3:4])';
    op(t,:) = (nanmean(all_vel(1,:))^2 + nanmean(all_vel(2,:))^2)^(0.5);
    dist_xy = squareform((pdist(all_pos(:,[1:G.num])','euclidean'))); 
    dist_xy(logical(eye(G.num))) = NaN;
    nnd(t,:) = min(min(dist_xy));
    heading(:,t) = atan2(all_vel(2,:), all_vel(1,:));
    if t == activate_time
        group_center = nanmean(all_pos,2);
        vec2center = all_pos - group_center;
        dis2center = (vec2center(1,:).^2 + vec2center(2,:).^2).^0.5;
        [~, recal_informed_id] = min(dis2center);
   end
    if t >= activate_time
        all_vel_mod = all_vel;
        all_vel_mod(:,informed_id) = [];
        group_vel = nanmean(all_vel_mod,2);
        informed_vel = all_vel(:,informed_id);
        r_acc(t) = dot(group_vel, resp_dir);
        informed_r_acc(t) = dot(informed_vel, resp_dir);
    end 
end
cyctime = 1;
max_r_acc_idx = find(r_acc == max(r_acc), 1);
try
    mean_acc = nanmean(r_acc(max_r_acc_idx:max_r_acc_idx+5));
catch
    mean_acc = nanmean(r_acc(size(savingData,1) - 5:size(savingData,1)));
end
resp_time = find(r_acc >= 0.85, 1);
if isempty(resp_time)
    resp_time = nan;
end
r_area = trapz(1 - r_acc(activate_time:end))/((size(savingData,1) - activate_time));
% if mean_acc < 0
%     mean_acc = nan;
% end
if plot_figure == 1
    figure;
    figSize_L = 10;
    figSize_W = 10;
    set(gcf, 'Units', 'centimeter','Position', [5 5 figSize_L figSize_W])
    axis equal
    hold on;box on;
    traj = savingData;
    x = squeeze(traj(1:G.total_step,:,1)) * 60;
    y = squeeze(traj(1:G.total_step,:,2)) * 60;
%     plot(x(:,1:end),y(:,1:end),'color',hex2rgb('BBBDBF'),'LineWidth',2)
    end_step = G.total_step;
    for p = 1:size(x,2)
%         if find(abs(y(1:end_step,p)) > 15)
%             continue
%         end
        patch([x(1:end_step,p)' NaN], [y(1:end_step,p)' NaN], [[1:end_step]/(end_step - 1)  NaN], ...
                                    'EdgeColor','interp','MarkerFaceColor','flat','LineWidth',2)
        colormap(turbo)
        hold on
    end
    h = colorbar('FontSize',15);
    t=get(h,'YTickLabel');
    t=strcat(t,'step');
    set(h,'YTickLabel',t);
    set(h,'Ticks',[1:10]')
    set(h, 'TickLabels', num2cell(floor(linspace(1, G.total_step-1,5))))
    set(h,'TicksMode','auto')
    set(get(h,'Title'),'string','time');

    end_step = G.total_step;
    hold on 
    plot(x(1:end_step,informed_id), y(1:end_step,informed_id),'k', 'LineWidth',3)
    xlabel('x (mm)');
    ylabel('y (mm)');
%     title("$\tau=$" + num2str(tau) + " $\alpha=$" + num2str(mu) + " $R_{visual}=$" + ...
%                     num2str(distTH),'Interpreter','latex')
    set(gca, 'Fontname', 'helvetica', 'FontSize', 15)

    figure;
    figSize_L = 8;
    figSize_W = 4;
    set(gcf, 'Units', 'centimeter','Position', [5 5 figSize_L figSize_W])
    draw_sec = 2;
%     plot([1:draw_sec:G.total_step]*0.2, r_acc(1:draw_sec:G.total_step), "LineWidth",2)
    plot([1:draw_sec:G.total_step]*cyctime, r_acc(1:draw_sec:G.total_step), "LineWidth",2)
    hold on
    plot([1:draw_sec:G.total_step]*cyctime, informed_r_acc(1:draw_sec:G.total_step),'Color','k', "LineWidth",3)
    hold on
%     scatter(turning_act_list, ones(1, size(turning_act_list,2)));
%     title("$r=$" + num2str(r_area),'Interpreter','latex')
    legend(["uninfo. robots", "info. robot"],'box','off')
    ylabel("accuracy")
    xlabel("time (step)")
    set(gca, 'Fontname', 'helvetica', 'FontSize', 15)

%     figure;
%     figSize_L = 10;
%     figSize_W = 4;
%     set(gcf, 'Units', 'centimeter','Position', [5 5 figSize_L figSize_W])
%     draw_sec = 1;
%     heading = rad2deg(heading);
%     group_heading = heading;
%     group_heading(informed_id,:) = [];
%     mean_group_heading = nanmean(group_heading,1);
%     plot([1:draw_sec:total_step]*cyctime, mean_group_heading(:,1:draw_sec:total_step), "LineWidth",2)
%     hold on
%     plot([1:draw_sec:total_step]*cyctime, heading(informed_id,1:draw_sec:total_step),'Color','k', "LineWidth",4)
%     hold on
%     ylabel("heading(deg)")
%     xlabel("time(s)")
%     set(gca, 'Fontname', 'helvetica', 'FontSize', 15)

    figure;
    figSize_L = 8;
    figSize_W = 4;
    set(gcf, 'Units', 'centimeter','Position', [5 5 figSize_L figSize_W])
    draw_sec = 1;
    plot([1:draw_sec:G.total_step]*cyctime, op(1:draw_sec:G.total_step), "LineWidth",2.5)
    ylabel("\phi")
    xlabel("time (step)")
    set(gca, 'Fontname', 'helvetica', 'FontSize', 15)
end
end