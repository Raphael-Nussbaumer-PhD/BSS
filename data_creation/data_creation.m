function [K_true, g_true, rho_true, K, g, G] = data_creation(grid, method, plotit)
% DATA_CREATION is basically creating all the data required for a simulation.
% INPUT:
%       - grid:         grid of the matrix to generate
%           -grid.nx:   nb of grid cell in x
%           -grid.x:    vector of the cell location [m]
%           -grid.dx:   cell size [m]
%       - method:       method to get data
%           -gen:       g_true, K_true and rho_true
%               -1:     read mat file
%               -2:     first K then rho and then g
%               -3:     first rho and then K and g
%           -samp:      K and g
%               -1:     borehole
%               -2:     random
%       - plotit:       choose to plot or not
% OUTPUT:
%       - K_true:      	Hydraulic conductivity true field, matrix (grid.nx x grid.ny) (data or generated)
%       - g_true:      	Electrical conductivity true field, matrix (grid.nx x grid.ny)  (data or from K_true)
%       - K:          	Hydraulic conductivity at some point, structure: location (K.x, K.y) of data (K.d) (sampled from K_true)
%       - g:          	Electrical conductivity at some point, structure: location (g.x, g.y) of data (g.d) (sampled from g_true)
%       - G:          	Electrical conductivity measured grid, matrix (G.nx x G.ny) of data (G.d) (ERT inverse)
%
% Author: Raphael Nussbaumer
% date : January 2014
% need to do : add assert() for input, flexible number of input var


% handle function for generating a fiel and all phsical relationship
f_new_field = @(grid,covar) fftma(grid.x(1),grid.dx,grid.x(end),grid.y(1),grid.dy,grid.y(end),covar);
f_Heinz = @(rho,v) 10.^(6.66 *rho - 4.97); % log_10(K) = 6.66 \rho - 4.97 + noise (Heinz et al., 2003)
f_Heinz_inv = @(K,v) (log10(K)+4.97)/ 6.66 ; % log_10(K) = 6.66 \rho - 4.97  + noise (Heinz et al., 2003)
f_Archie = @(rho,v) 43 *real(rho.^1.4);  % \sigma = \sigma_W \rho ^m  + noise (Archie, 1942)
f_Archie_inv = @(sigma,v) (sigma/43).^(1/1.4) ;  % \sigma = \sigma_W \rho ^m  + noise (Archie, 1942)
f_KC = @(rho,d10,v) 9810/0.001002 * rho.^3./(1-rho).^2 .* d10^2/180; % Kozeny-Carman @20°C


switch method.gen
    case 1 % Read Data
        load('data.mat');
        [X,Y]=meshgrid(x,y);
        F = scatteredInterpolant(X(:),Y(:),sigma_true(:),'linear','nearest');
        g_true= F(grid.X,grid.Y);
        %g_true=interp2(x,y,sigma_true,grid.X,grid.Y,'nearest','extrap');
        assert(~any(isnan(g_true(:))),'error')
        % figure;hold on;ksdensity(g_true(:));ksdensity(sigma_true(:))
        % figure;subplot(2,1,1);imagesc(g_true);subplot(2,1,2);imagesc(sigma_true);
        clear sigma_obs sigma_obs_err sigma_true
        
        rho_true = f_Archie_inv(g_true);
        K_true =  f_Heinz(rho_true);
        % K_true=nan(size(g_true)); warning('K_true not generated. read from file unavailable')
        % rho_true=nan(size(g_true)); warning('K_true not generated. read from file unavailable')
        method.G=1;
        
    case 2 % from K

        model     = 4; % model type
        k.rotation  = 0;
        k.range     = [160;15]; % measure in unit
        covar.modele = [model k.range(1) k.range(2) k.rotation; 1 1 1 1];
        covar.c   = [.99; 0.01];
        K_true_n=f_new_field(grid,covar);
        % figure;imagesc(K_true_n)
        K_true= 10.^(-3.18 + K_true_n * sqrt(0.36)); % put it as a log normal dist.
        rho_true=f_Heinz_inv(K_true) ; % noise: f_new_field(0,0.025,3.5,1)
        g_true = f_Archie(rho_true); % noise: f_new_field(0,0.25,3.5,1);
        method.G=2;
        plotit2=0;
        
        clear K_true_n covar model
    case 3 % from rho

  
end


% 3. Simulate high-resolution point measurement of K
K = sampling_pt(grid,K_true,method.samp);


% 4. Simulate high-resolution point measurement of g
g = sampling_pt(grid,g_true,method.samp);


% 5. Simulate low-resolution grid measurement of G
G = meas_G_grid(grid,g_true,method.G,plotit2);

% 6. Plot
if plotit
    figure;
    % subplot(4,1,1); pcolor(grid.x,grid.y,rho_true); shading flat; xlabel('x[m]'); ylabel('y [m]'); title('True Porosity (rho_{true})'); colorbar;
    subplot(4,1,1); pcolor(grid.x,grid.y,log10(K_true)); shading flat; hold on; plot(K.x, K.y, 'or'); xlabel('x[m]'); ylabel('y [m]'); title('Log True Hydraulic Conudctivity K_{true} and sampled point location K'); colorbar;
    subplot(4,1,2); pcolor(grid.x,grid.y,g_true); shading flat; hold on; plot(g.x, g.y, 'or'); xlabel('x[m]'); ylabel('y [m]'); title('True Electrical Conductivity g_{true} and sampled point location g'); colorbar;
    subplot(4,1,3); pcolor(grid.x,grid.y,G.d); shading flat; xlabel('x[m]'); ylabel('y [m]'); title('Electrical Conductivity Tomography G'); colorbar;
    subplot(4,1,4); pcolor(grid.x,grid.y,G.std); shading flat; xlabel('x[m]'); ylabel('y [m]'); title('Electrical Conductivity Tomography error G_{std}'); colorbar;
end
end