function output=readOutput(d,grid_G)

if d.job_type == 1 % inverse solution
    i=d.max_iterations;
    filename=['f001.' sprintf('%03d',i)];
    while exist([filename '_res.dat'], 'file') == 0 && i>0
        i=i-1;
        filename=['f001.' sprintf('%03d',i)];
    end
    if i==0 && exist('f001_res.dat', 'file') == 0
        error('no file...')
    else
        filename='f001';
    end
    
    % read resistivity result
    data=dlmread([filename '_res.dat']);
    % output.x=unique(data(:,1));
    % output.y=-unique(data(:,2));
    output.res=flipud(reshape(data(:,3),grid_G.ny,grid_G.nx));
    
    % read error result
    data            = dlmread([d.filepath filename '_err.dat'],'',1,0);
    output.err      = data(:,1);
    output.pseudo   = data(:,3);
    output.wight    = data(:,5);
    
    if d.res_matrix==1 % 1-'sensitivity' matrix
        try
            data=dlmread([d.filepath filename '_sen.dat']);
            output.sen=flipud(reshape(data(:,3),grid_G.ny,grid_G.nx));
        catch
            output.sen=NaN;
        end
    elseif d.res_matrix==2 % 2-true resolution matrix
        try
            data=dlmread([d.filepath filename '_red.dat']);
            output.rad=flipud(reshape(data(:,3),grid_G.ny,grid_G.nx));
        catch
            output.rad=NaN;
        end
    end
    
else
    data=dlmread([d.filepath 'forward_model.dat']);
    % output.x=unique(data(:,1));
    % output.y=-unique(data(:,2));
    output.re=flipud(reshape(data(:,3),grid_G.ny,grid_G.nx));
    
    data=dlmread([d.filepath 'R2_forward.dat'],'',1,0);
    assert(size(data,2)==7)
    output.pseudo=data(:,7);
end


% Interpolation
if numel(d.pseudo_x) == numel(output.pseudo)
    f=scatteredInterpolant(d.pseudo_y,d.pseudo_x,output.pseudo,'nearest','none');
    output.pseudo_interp = f({grid_G.y,grid_G.x});
    
    if d.job_type == 1
        f=scatteredInterpolant(d.pseudo_y,d.pseudo_x,output.err,'nearest','none');
        output.err_interp = f({grid_G.y,grid_G.x});
    end
else
    output.pseudo_interp = nan(numel(grid_G.x),numel(grid_G.y));
end


end