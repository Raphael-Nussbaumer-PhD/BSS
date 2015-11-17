function k0=kringing_coef(Y,X,k,parm,i_realisation)
%% kriging return the mean and variance estimate at the point Y.pt
%
% INPUT:
% * Y       : Primary variable
% * X       : Secondary variable
% * k       : kriging information
%
% OUTPUT:
% * krig_m  : kriging mean estimate
% * krig_s  : kriging variance estimate
%
% * *Author:* Raphael Nussbaumer (raphael.nussbaumer@unil.ch)
% * *Date:* 02.02.2015

if parm.neigh
   %% *SELECTION OF DATA*
    % Use Supergrid Block for hard data and spiral search for previously
    % simulated point.
    
    % 1. Super Grid Block from Hard Data:
    sb_j = min([round((Y.y(Y.pt.y)-k.sb.y(1))/k.sb.dy +1)'; k.sb.ny]);
    sb_i = min([round((Y.x(Y.pt.x) -k.sb.x(1))/k.sb.dx +1)'; k.sb.nx]);
    sb_mask_all = reshape(k.sb.mask(sb_j,sb_i,:),X.n,1);
    
    [~,sb_id] = sort( sqrt( ( (X.x(sb_mask_all)-Y.x(Y.pt.x))./k.range(1) ).^2 + ( (X.y(sb_mask_all)-Y.y(Y.pt.y))./k.range(2) ).^2 ) );
    sb_mask_all_id = find(sb_mask_all);
    k0.sb_mask = false(X.n,1);
    k0.sb_mask( sb_mask_all_id(sb_id(1:min(k.nb_neigh(2,5),numel(sb_id)))))=true;
    
    
    
    % 2. Spiral search per quandrant

    nn_max=length(k.ss.el.dist_s);
    n=[0 0 0 0];
    sel_ss_idx=cell(4,1);
    
    for q=1:4
        sel_ss_idx{q}=nan(k.nb_neigh(2,q),2);
        nn=2; % 1 is the point itself... therefore unknown
        while n(q)<k.nb_neigh(2,q) && nn<=nn_max && k.ss.el.dist_s(nn)<=k.wradius % while not exceed number of point wanted and still inside the ellipse
            it = Y.pt.x + k.qs(q,1)*k.ss.el.X_s(nn);
            jt = Y.pt.y + k.qs(q,2)*k.ss.el.Y_s(nn);
            if it>0 && jt>0 && it<=Y.nx && jt <=Y.ny % check to not be outside the grid
                if ~isnan(Y.m_ns{i_realisation}(jt,it)) % check if it,jt exist
                    n(q)=n(q)+1;
                    sel_ss_idx{q}(n(q),:) = [jt it];
                end
            end
            nn=nn+1;
        end
        sel_ss_idx{q}=sel_ss_idx{q}(1:n(q),:); % only the max number of point found.
    end
    
    k0_ss_idx = unique([sel_ss_idx{1};sel_ss_idx{2};sel_ss_idx{3};sel_ss_idx{4}],'rows');
    k0.ss_mask = sub2ind([Y.ny, Y.nx],k0_ss_idx(:,1),k0_ss_idx(:,2));
    
    % 3. Combine SuperBlock Point and Spiral Search point.
    sel_g=[X.x(k0.sb_mask) X.y(k0.sb_mask); Y.X(k0.ss_mask) Y.Y(k0.ss_mask)];
    

else
    sel_g_ini=[X.x X.y; Y.X(~isnan(Y.m{i_realisation})) Y.Y(~isnan(Y.m{i_realisation}))]; % remove the u
    % Just remove point outside search radius and keep 
    % This is identical (more or less) to cokri_cam (sort and selection)
    center = [Y.x(Y.pt.x) Y.y(Y.pt.y)];
    dist = sqrt(((sel_g_ini(:,1)-center(1))/k.range(1)).^2 + ((sel_g_ini(:,2)-center(2))/k.range(2)).^2);
    [dist_s, idx] = sort(dist);
    sb_i=1;
    k0.mask=[];
    sel_g=[];
    while sb_i<sum(k.nb_neigh(2,:)) && dist_s(sb_i) < k.wradius
        k0.mask=[k0.mask; idx(sb_i)];
        sel_g = [sel_g; sel_g_ini(idx(sb_i),:)];
        sb_i=sb_i+1;
    end
end

% disable for time saving
assert((size(unique(sel_g,'rows'),1)==size(sel_g,1)), 'None unique point for kriging: ')
% assert(size(sel_g,1)>2, 'Not enough point for kriging: ')

%%
% * *KRIGING*: Find his kringing value in noraml space:

 a0_C=covardm(sel_g,[Y.x(Y.pt.x) Y.y(Y.pt.y)],k.model,k.var,parm.k.cx);
 ab_C=covardm(sel_g,sel_g,k.model,k.var,parm.k.cx);
% a0_C=covardm_old(sel_g,[Y.x(Y.pt.x) Y.y(Y.pt.y)],k.model,k.var);
% ab_C=covardm_old(sel_g,sel_g,k.model,k.var);

k0.lambda = ab_C \ a0_C; % Ordinary
k0.s = sum(k.var) - k0.lambda'*a0_C;

% disable for time saving
 assert(~any(isnan(k0.lambda)),'the kriging coeff is NaN')
 assert(k0.s>0,'the kriging std result is less than zero')

end


%% Previous Version :

% Version1 : classical spiral search, add all hard data later. pb: have
% more data than wanted
%
% % Super Grid Block from Hard Data:
% k0.sb_mask = reshape(k.sb.mask(min([round((Y.y(Y.pt.y)-k.sb.y(1))/k.sb.dy +1)'; k.sb.ny]), ...
%     min([round((Y.x(Y.pt.x) -k.sb.x(1))/k.sb.dx +1)'; k.sb.nx])   , :),X.n,1);
% 
% % Spiral search per quandrant
% nn_max=length(k.ss.el.dist_s);
% n=[0 0 0 0];
% sel_ss_idx=cell(4,1);
% 
% for q=1:4
%     sel_ss_idx{q}=nan(k.nb_neigh(2,q),2);
%     nn=2; % 1 is the point itself... therefore unknown
%     while n(q)<k.nb_neigh(2,q) && nn<=nn_max && k.ss.el.dist_s(nn)<=k.wradius % while not exceed number of point wanted and still inside the ellipse
%         it = Y.pt.x + k.qs(q,1)*k.ss.el.X_s(nn);
%         jt = Y.pt.y + k.qs(q,2)*k.ss.el.Y_s(nn);
%         if it>0 && jt>0 && it<=Y.nx && jt <=Y.ny % check to not be outside the grid
%             if ~isnan(Y.m_ns{i_realisation}(jt,it)) % check if it,jt exist
%                 n(q)=n(q)+1;
%                 sel_ss_idx{q}(n(q),:) = [jt it];
%             end
%         end
%         nn=nn+1;
%     end
%     sel_ss_idx{q}=sel_ss_idx{q}(1:n(q),:); % only the max number of point found.
% end
% 
% k0_ss_idx = unique([sel_ss_idx{1};sel_ss_idx{2};sel_ss_idx{3};sel_ss_idx{4}],'rows');
% k0.ss_mask = sub2ind([Y.ny, Y.nx],k0_ss_idx(:,1),k0_ss_idx(:,2));
% 
% % Combine SuperBlock Point and Spiral Search point.
% sel_g=[X.x(k0.sb_mask) X.y(k0.sb_mask); Y.X(k0.ss_mask) Y.Y(k0.ss_mask)];
   


% Version 2 : 
% % Super Grid Block from Hard Data:
% k0_sb_mask_all = find(reshape(k.sb.mask(min([round((Y.y(Y.pt.y)-k.sb.y(1))/k.sb.dy +1)'; k.sb.ny]), ...
%     min([round((Y.x(Y.pt.x) -k.sb.x(1))/k.sb.dx +1)'; k.sb.nx])   , :),X.n,1));
% 
% q_X = [sign(X.x(k0_sb_mask_all)-Y.x(Y.pt.x))  sign(X.y(k0_sb_mask_all)-Y.y(Y.pt.y))];
% 
% 
% % Spiral search per quandrant
% n_ss=[0 0 0 0];
% n_sb=[0 0 0 0];
% sel_ss_idx=nan(4,max(k.nb_neigh(2,:)));
% sel_ss_idy=nan(4,max(k.nb_neigh(2,:)));
% sel_sb_id=nan(4,max(k.nb_neigh(2,:)));
% 
% for q=1:4
%     nn=1; % 1 is the point itself... therefore unknown
% 
%     k0_sb_mask_q=k0_sb_mask_all( (k.qs(q,1)==q_X(:,1)&k.qs(q,2)==q_X(:,2)) | (k.qs2(q,1)==q_X(:,1)&k.qs2(q,2)==q_X(:,2)) );
%     q_X_dist = ((X.x(k0_sb_mask_q)-Y.x(Y.pt.x))/k.range(1)).^2 + ((X.y(k0_sb_mask_q)-Y.y(Y.pt.y))/k.range(2)).^2;
% 
%     k.ss.el.X_c = Y.pt.x + k.ss.el.X_f{q};
%     k.ss.el.Y_c = Y.pt.y + k.ss.el.Y_f{q};
%     id = find(k.ss.el.X_c>0 & k.ss.el.Y_c>0 & k.ss.el.X_c<=Y.nx & k.ss.el.Y_c<=Y.ny & k.ss.el.dist_f{q}<=k.wradius);
%     k.ss.el.X_cf = k.ss.el.X_c(id);
%     k.ss.el.Y_cf = k.ss.el.Y_c(id);
% 
%     k.ss.el.dist_cf = k.ss.el.dist_f{q}(id);
%     nn_max=numel(k.ss.el.dist_cf);
% 
%     while (n_ss(q)+n_sb(q))<k.nb_neigh(2,q) % while enough space and not reached the end...
%         if nn<=nn_max && ~isnan(Y.m_ns{i_realisation}(sub2ind([Y.ny, Y.nx],k.ss.el.Y_cf(nn),k.ss.el.X_cf(nn))) % check if value exist
%             if any(q_X_dist<k.ss.el.dist_s(nn)) % add all hard data point in between
%                 id_sb = q_X_dist<k.ss.el.dist_s(nn);
%                 if sum(id_sb) + n_ss(q) + n_sb(q) < k.nb_neigh(2,q) % if we can add all point
%                     k0.sb_mask(q,n_sb(q)+(1:sum(id_sb)))=k0_sb_mask_q(id_sb); % add new point
%                     k0_sb_mask_q(id_sb)=[]; % remove form the count
%                     q_X_dist(id_sb)=[];
%                     n_sb(q) = n_sb(q) + sum(id_sb);
%                 else
%                     n_tofill = k.nb_neigh(2,q)-n_ss(q)-n_sb(q);
%                     [~,id]=sort(q_X_dist(id_sb));
%                     k0_sb_mask_q = k0_sb_mask_q(id_sb);
%                     sel_sb_id(q,(n_sb(q)+(1:n_tofill))) = k0_sb_mask_q(id(1:n_tofill));
%                     n_sb(q) = n_sb(q) + n_tofill;
%                     break % full: terminate
%                 end
%             end
%             % add current point
%             n_ss(q)=n_ss(q)+1;
%             sel_ss_idy(q,n_ss(q)) = k.ss.el.X_cf(nn);
%             sel_ss_idx(q,n_ss(q)) = k.ss.el.Y_cf(nn);
%         end
%         if nn>=nn_max
%             id_sb = q_X_dist<k.wradius;
%             if any(id_sb)
%                 if sum(id_sb) + n_ss(q) + n_sb(q) < k.nb_neigh(2,q) % if we can add all point
%                     k0.sb_mask(q,n_sb(q)+(1:sum(id_sb)))=k0_sb_mask_q(id_sb); % add new point
%                 else
%                     n_tofill = k.nb_neigh(2,q)-n_ss(q)-n_sb(q);
%                     [~,id]=sort(q_X_dist(id_sb));
%                     k0_sb_mask_q = k0_sb_mask_q(id_sb);
%                     sel_sb_id(q,(n_sb(q)+(1:n_tofill))) = k0_sb_mask_q(id(1:n_tofill));
%                 end
%             end
%             break;
%         end
%         nn=nn+1;
%     end
% end
% 
% %k0_ss_idx = unique([sel_ss_idx{1};sel_ss_idx{2};sel_ss_idx{3};sel_ss_idx{4}],'rows');
% sel_ss_id = sub2ind([Y.ny, Y.nx],sel_ss_idy,sel_ss_idx);
% 
% k0.ss_mask=sel_ss_id(~isnan(sel_ss_id));
% k0.sb_mask=sel_sb_id(~isnan(sel_sb_id));
% 
% % Combine SuperBlock Point and Spiral Search point.
% sel_g=[X.x(k0.sb_mask) X.y(k0.sb_mask); Y.X(k0.ss_mask) Y.Y(k0.ss_mask)];
    




% Version 3
%% *SELECTION OF DATA*
% % Use Supergrid Block for hard data and spiral search for previously
% % simulated point. combine all the point and check few stuff
% 
% % Super Grid Block from Hard Data:
% sb_i=min([round((Y.x(Y.pt.x) -k.sb.x(1))/k.sb.dx +1)'; k.sb.nx]);
% sb_j=min([round((Y.y(Y.pt.y)-k.sb.y(1))/k.sb.dy +1)'; k.sb.ny]);
% 
% 
% 
% % Spiral search per quandrant
% n_ss=[0 0 0 0];
% n_sb=[0 0 0 0];
% sel_ss_idx=nan(4,max(k.nb_neigh(2,:)));
% sel_ss_idy=nan(4,max(k.nb_neigh(2,:)));
% sel_sb_id=nan(4,max(k.nb_neigh(2,:)));
% 
% for q=1:4
% 
%     sb_q_dist = sqrt( ( (X.x(k.sb.mask{sb_j,sb_i,q})-Y.x(Y.pt.x))./k.range(1) ).^2 + ( (X.y(k.sb.mask{sb_j,sb_i,q})-Y.y(Y.pt.y))./k.range(2) ).^2 );
%     sb_q_mask = k.sb.mask_vec{sb_j,sb_i,q};
% 
%     k.ss.el.X_c = Y.pt.x + k.ss.el.X_f{q};
%     k.ss.el.Y_c = Y.pt.y + k.ss.el.Y_f{q};
%     id_ss_1 = find(k.ss.el.X_c>0 & k.ss.el.Y_c>0 & k.ss.el.X_c<=Y.nx & k.ss.el.Y_c<=Y.ny & k.ss.el.dist_f{q}<=k.wradius);
%     id_ss_2 = find(~isnan(Y.m_ns{i_realisation}(sub2ind([Y.ny, Y.nx],k.ss.el.Y_c(id_ss_1),k.ss.el.X_c(id_ss_1)))));
% 
%     ss_dist = k.ss.el.dist_f{q}(id_ss_1(id_ss_2));
% 
%     for nn=1:numel(ss_dist)
%         % 1. add all hard data point in between
%         if any(sb_q_dist<ss_dist(nn)) 
%             id_sb_1 = find(sb_q_dist<ss_dist(nn));
%             if numel(id_sb_1) + n_ss(q) + n_sb(q) < k.nb_neigh(2,q) % if we can add all point
%                 sel_sb_id(q,n_sb(q)+(1:numel(id_sb_1)))=sb_q_mask(id_sb_1); % add new point
%                 sb_q_mask(id_sb_1)=[]; % remove form the count
%                 sb_q_dist(id_sb_1)=[];
%                 n_sb(q) = n_sb(q) + numel(id_sb_1);
%             else
%                 n_tofill = k.nb_neigh(2,q)-n_ss(q)-n_sb(q);
%                 [~,id_sb_2]=sort(sb_q_dist(id_sb_1));
%                 sel_sb_id(q,(n_sb(q)+(1:n_tofill))) = sb_q_mask(id_sb_1(id_sb_2(1:n_tofill)));
%                 n_sb(q) = n_sb(q) + n_tofill;
%                 break % full: terminate
%             end
%         end
% 
%         %2. Add current point
%         n_ss(q)=n_ss(q)+1;
%         sel_ss_idy(q,n_ss(q)) = k.ss.el.Y_c(id_ss_1(id_ss_2(nn)));
%         sel_ss_idx(q,n_ss(q)) = k.ss.el.X_c(id_ss_1(id_ss_2(nn)));
% 
%         %3. check if fill
%         if n_ss(q)+n_sb(q) >= k.nb_neigh(2,q)
%             break;
%         end
%     end
% 
%     % 4. When spiral search is finish, we can fill remaning space with
%     % whatever super blocks left
%     if n_ss(q)+n_sb(q) < k.nb_neigh(2,q)
%         if any(sb_q_dist < k.wradius)
%             id_sb_1 = find(sb_q_dist < k.wradius);
%             if numel(id_sb_1) + n_ss(q) + n_sb(q) < k.nb_neigh(2,q) % if we can add all point
%                 sel_sb_id(q,n_sb(q)+(1:numel(sb_q_mask(id_sb_1))))= sb_q_mask(id_sb_1); % add new point
%             else
%                 n_tofill = k.nb_neigh(2,q)-n_ss(q)-n_sb(q);
%                 [~,id_sb_2] = sort(sb_q_dist(id_sb_1));
%                 sel_sb_id(q,(n_sb(q)+(1:n_tofill))) = sb_q_mask(id_sb_1(id_sb_2(1:n_tofill)));
%             end
%         end
%     end
% end
% 
% % k0_ss_idx = unique([sel_ss_idx{1};sel_ss_idx{2};sel_ss_idx{3};sel_ss_idx{4}],'rows');
% sel_ss_id = sub2ind([Y.ny, Y.nx],sel_ss_idy(:),sel_ss_idx(:));
% 
% k0.ss_mask=sel_ss_id(~isnan(sel_ss_id));
% k0.sb_mask=sel_sb_id(~isnan(sel_sb_id));
% 
% assert(all(k0.ss_mask>0))
% assert(all(k0.sb_mask>0))
% assert(numel(k0.ss_mask)+numel(k0.sb_mask)>0)
% 
% % Combine SuperBlock Point and Spiral Search point.
% sel_g=[X.x(k0.sb_mask) X.y(k0.sb_mask); Y.X(k0.ss_mask) Y.Y(k0.ss_mask)];
% Y.m_ns{i_realisation}(k0.ss_mask)
    
 
% Version 4
% % Spiral search per quandrant
% ss_x = Y.pt.x + k.ss.el.X_f;
% ss_y = Y.pt.y + k.ss.el.Y_f;
% id_ss_1 = ss_x>0 & ss_y>0 & ss_x<=Y.nx & ss_y<=Y.ny & k.ss.el.dist_f<=k.wradius;
% 
% 
% sel_ss_id=cell(4);
% 
% for q=1:4
%     id = sub2ind([Y.ny Y.nx], ss_y(id_ss_1(:,q),q), ss_x(id_ss_1(:,q),q));
%     id_ss_2 = find(~isnan(Y.m_ns{i_realisation}( id )));
%     sel_ss_id{q} = id(id_ss_2( 1:min(k.nb_neigh(2,q),numel(id_ss_2))) );
% 
%     sel_ss_dist = k.ss.el.dist_f(id_ss_1(1:min(k.nb_neigh(2,q),numel(id_ss_2)),q),q);
% 
%     sel_sb_mask = reshape(k.sb.mask(min([round((Y.y(Y.pt.y)-k.sb.y(1))/k.sb.dy +1)'; k.sb.ny]), ...
%     min([round((Y.x(Y.pt.x) -k.sb.x(1))/k.sb.dx +1)'; k.sb.nx])   , :),X.n,1);
% 
%      sel_sb_dist = sqrt( ( (X.x(sel_sb_mask)-Y.x(Y.pt.x))./k.range(1) ).^2 + ( (X.y(sel_sb_mask)-Y.y(Y.pt.y))./k.range(2) ).^2 );
% 
%      sort([sel_ss_dist;sel_sb_dist])
% end

% Option 1: when few points are filled (best when no using multi-grid on large grid)
% %     ss_x = Y.pt.x + k.ss.el.X_f;
% %     ss_y = Y.pt.y + k.ss.el.Y_f;
% %     id_ss_1 = ss_x>0 & ss_y>0 & ss_x<=Y.nx & ss_y<=Y.ny & k.ss.el.dist_f<=k.wradius;
% % 
% % 
% %     sel_ss_id=cell(4,1);
% %     for q=1:4
% %         id = sub2ind([Y.ny Y.nx], ss_y(id_ss_1(:,q),q), ss_x(id_ss_1(:,q),q));
% %         id_ss_2 = find(~isnan(Y.m_ns{i_realisation}( id )));
% %         sel_ss_id{q} = id(id_ss_2( 1:min(k.nb_neigh(2,q),numel(id_ss_2))) );
% % 
% %         % sel_ss_dist = k.ss.el.dist_f(id_ss_1(1:min(k.nb_neigh(2,q),numel(id_ss_2)),q),q);
% %     end
% %    k0.ss_mask = [sel_ss_id{1};sel_ss_id{2};sel_ss_id{3};sel_ss_id{4}];
    
    
% Option 2

    