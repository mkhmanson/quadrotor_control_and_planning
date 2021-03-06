function [ desired_state ] = trajectory_generator(t, qn, map, path)
% TRAJECTORY_GENERATOR: Turn a Dijkstra or A* path into a trajectory
%
% NOTE: This function would be called with variable number of input
% arguments. In init_script, it will be called with arguments
% trajectory_generator([], [], map, path) and later, in test_trajectory,
% it will be called with only t and qn as arguments, so your code should
% be able to handle that. This can be done by checking the number of
% arguments to the function using the "nargin" variable.

% map: The map structure returned by your load_map function
% path: This is the path returned by your planner (dijkstra function)
% desired_state: Contains all the information that is passed to the
% controller, as in phase 2

% It is suggested to use "persistent" variables to store map and path
% during the initialization call of trajectory_generator.
persistent qs qf AX AY AZ t0;
if nargin == 4
    % get cornerpoints
    t0 = 0;    
    % optional smoothing for consecutive turn in x,y
    n=size(path{1,1},1);
    cutpoints = path{1,1}(1,:);
    i=1;
    while i < n
%         if round(abs(cornerpoints(i+1,:)-cornerpoints(i-1,:)),2) == [map.xy_res map.xy_res 0]
%          if norm(cornerpoints(i+1,:)-cornerpoints(i-1,:)) < map.xy_res*5 && ... % map.xy_res*5 is safe here
           if n-i ==1
               cutpoints = [cutpoints;path{1,1}(n,:)];
               break
           else
           for j = 2:n-i
               step = (path{1,1}(i+j,:)-path{1,1}(i,:))/11;
               test_points = [path{1,1}(i,:)+step;path{1,1}(i,:)+2*step;...
                              path{1,1}(i,:)+3*step;path{1,1}(i,:)+4*step;... 
                              path{1,1}(i,:)+5*step; path{1,1}(i,:)+6*step;...
                              path{1,1}(i,:)+7*step;path{1,1}(i,:)+8*step;...
                              path{1,1}(i,:)+9*step;path{1,1}(i,:)+10*step];
               test = collide(map, test_points);
               if isequal(test,zeros(10,1)) % no obstacle between two cornerpoints
                   if j == n-i
                       cutpoints = [cutpoints;path{1,1}(n,:)];
                       i = n;
                       break
                   else
                       continue
                   end
               end
               cutpoints = [cutpoints;path{1,1}(i+j-1,:)]; % the last longest point without collide
               i = i+j-1;
               break
           end           
           end
    end
%     if  norm(cutpoints(end,:)-path{1,1}(n,:))>1e-5
%         cutpoints = [cutpoints;path{1,1}(n,:)];
%     end
    
    c=size(cutpoints,1);
    qs = path{1,1}(1,:);
    qf = path{1,1}(n,:);
    
    t_step = 0.9; % 1 second for 1 squreroot step in x,y,z direction
    
    % generate trajectory through waypoints
    tend =0;
    for j =1:c-1
        qstart = cutpoints(j,:);  
        qend = cutpoints(j+1,:);
        tstart = tend;
        tend = tstart+sqrt(norm(qend-qstart))*t_step; % gurantee the velocity
        % vstart,vend,astart,aend are [0 0 0]
    Q = [1 tstart (tstart)^2 (tstart)^3 (tstart)^4 (tstart)^5;1 tend (tend)^2 (tend)^3 (tend)^4 (tend)^5;
        0 1 2*tstart 3*(tstart)^2 4*(tstart)^3 5*(tstart)^4 ; 0 1 2*tend 3*(tend)^2 4*(tend)^3 5*(tend)^4;
        0 0 2 6*tstart 12*(tstart)^2 20*(tstart)^3; 0 0 2 6*tend 12*(tend)^2 20*(tend)^3];
    A = Q\[qstart; qend; 0 0 0; 0 0 0;0 0 0;0 0 0];
    
    AX= [AX,A(:,1)];
    AY= [AY,A(:,2)];
    AZ= [AZ,A(:,3)];
    t0 = [t0;tend];
    end
    
    
elseif nargin == 2
    % assign trajectory to time interval
    l = size(t0,1);
    if t < 0
         desired_state.pos = [qs(1); qs(2); qs(3)]; % stay at start point
         desired_state.vel = [0; 0; 0];
         desired_state.acc = [0; 0; 0];
    elseif t >= t0(l)
         desired_state.pos = [qf(1); qf(2); qf(3)]; % stay at end point
         desired_state.vel = [0; 0; 0];
         desired_state.acc = [0; 0; 0];
    else
        for k = 1:l-1
            if t>= t0(k) && t< t0(k+1)
                A = [AX(:,k), AY(:,k), AZ(:,k)];
                desired_state.pos = A'*[1; t; t^2; t^3; t^4; t^5];
                desired_state.vel = A'*[0; 1; 2*t; 3*t^2; 4*t^3; 5*t^4];
                desired_state.acc = A'*[0; 0; 2; 6*t; 12*t^2; 20*t^3];
                break
            end
        end
    end    

desired_state.yaw = 0; %leave as 0
desired_state.yawdot = 0;

end



end


