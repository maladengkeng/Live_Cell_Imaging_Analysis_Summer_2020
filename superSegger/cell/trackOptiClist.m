function [clist] = trackOptiClist(dirname,CONST,header)
% trackOptiClist : generates an array called the clist
% which contains non time dependent information for each cell.
% Fluorescence values contained are for at birth time.
% To see the information contained type clist.def'.
%
% INPUT :
%       dirname : seg folder eg. maindirectory/xy1/seg
%       CONST : segmentation constants
%       header : string displayed with information
% OUTPUT :
%       clist :
%           .data : array of cell variables versus cells.
%           .def : definitions of variables in clist
%           .data3D : variables vs cells vs time
%           .def3D : definititions of variables used in data3D.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins.
% University of Washington, 2016
% This file is part of SuperSegger.
%
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('header','var')
    header = [];
end

if(nargin<1 || isempty(dirname))
    dirname = '.';
end
dirname = fixDir(dirname);

% Get the track file names...
contents=dir([dirname '*_err.mat']);



imRangeGlobal = [];



if isempty( contents )
    clist.data = [];
    clist.def={};
    clist.gate=[];
else
    data_c = loaderInternal([dirname,contents(end).name]);
    MAX_CELL = max(50000, max(data_c.regs.ID) + 100);
    if isempty(MAX_CELL)
        MAX_CELL = 50000;
    end
    num_im = numel(contents);
    
    if CONST.parallel.show_status
        h = waitbar( 0, 'Clist is being built.');
        cleanup = onCleanup( @()( delete( h ) ) );
    else
        h = [];
    end
    
    clist = [];
    [setter,clist.def3D]  = clistSetter ();
    clist.def = setter(:,1)';
    tmpFields = setter(:,2)';
    clist3d_ind = find([setter{:,4}]); % must use find.
    death_ind = find([setter{:,3}]); % death fields: updated in every frame
    clist_tmp = nan( MAX_CELL, numel( clist.def));
    clist_3D  = nan( MAX_CELL, numel( clist.def3D), num_im );
    clist_tmp(:,1) = 0;
    
    % calculating indexes of values used during calculations
    lengthFields = find(strcmp(tmpFields,'data_c.regs.L1'));
    index_lold = intersect(lengthFields,death_ind);
    index_lbirth = setdiff(lengthFields,death_ind);
    index_ID= strcmp(tmpFields,'ID');
    index_dlmaxOld = find(strcmp(tmpFields,'dlmax'));
    index_dlminOld = strcmp(tmpFields,'dlmin');
    index_ehist = find(strcmp(tmpFields,'error_frame'));
    
    
    prog  = [];
    prog0 = [];
    prog_ = [];
    gen_  = [];
    gen0_ = [];

    
    % loop through all the images (*err.mat files)
    for i = 1:num_im
        data_c = loaderInternal([dirname,contents(i).name]);
        
        % get info on max and min values of each channel over all timesteps
        if isfield( data_c, 'imRange' )
            if isempty( imRangeGlobal )
                imRangeGlobal = data_c.imRange;
            else
               
                for kk = 1:size( imRangeGlobal, 2 )                    
                    imRangeGlobal(1,kk) = min( [data_c.imRange(1,kk),imRangeGlobal(1,kk)] );
                    imRangeGlobal(2,kk) = max( [data_c.imRange(2,kk),imRangeGlobal(2,kk)] );
                end
            end
        end
        
        if ~isempty( data_c.CellA)
            % record the number of cell neighbors
            if CONST.trackOpti.NEIGHBOR_FLAG && ...
                    ~isfield( data_c.CellA{1}, 'numNeighbors' )
                for ii = 1:data_c.regs.num_regs
                    nei_ = numel(trackOptiNeighbors(data_c,ii));
                    data_c.CellA{ii}.numNeighbors = nei_ ;
                end
            end
            
            % figure out which cells are new born.
            maxID = max(clist_tmp(:,index_ID));
            ID = data_c.regs.ID;
            birthID_flag = (ID>maxID);
            ID_non_zero_flag = (ID>0);
            
            ci = and( ~birthID_flag, logical(ID));
            IDlog = ID>0;
            ID_non_zero = ID(IDlog);
            
            lold = nan(1,numel(ID));
            lbirth = nan(1,numel(ID));
            dlmaxOld = nan(1,numel(ID));
            dlminOld = nan(1,numel(ID));
            error_frame = nan(1,numel(ID));
            
            error_frame(IDlog) = clist_tmp(ID_non_zero,index_ehist);
            lold(IDlog) = clist_tmp(ID_non_zero,index_lold);
            lbirth(IDlog) = clist_tmp(ID_non_zero,index_lbirth);
            dlmaxOld(IDlog) = clist_tmp(ID_non_zero,index_dlmaxOld);
            dlminOld(IDlog) = clist_tmp(ID_non_zero,index_dlminOld);
            
            regnum = (1:data_c.regs.num_regs)';
            zz = zeros( data_c.regs.num_regs, 1);
            
            ehist = data_c.regs.ehist;
            set_error_this_frame = and( logical(ehist),isnan(error_frame) );
            error_frame(set_error_this_frame) = i;
            
            cell_dist = drill(data_c.CellA,'.cell_dist');
            pole_age  = drill(data_c.CellA,'.pole.op_age');
            fl1sum = drill(data_c.CellA,'.fl1.sum');
            fl2sum  = drill(data_c.CellA,'.fl2.sum');
            Area = drill(data_c.CellA,'.coord.A');
            xpos = drill(data_c.CellA,'.coord.rcm(1)');
            ypos = drill(data_c.CellA,'.coord.rcm(2)');
            numNeighbors = drill(data_c.CellA,'.numNeighbors');
            gray = drill(data_c.CellA,'.gray');
            
            locus1_L1 = drill(data_c.CellA, '.locus1(1).longaxis');
            locus1_L2 = drill(data_c.CellA, '.locus1(1).shortaxis');
            locus1_s = drill(data_c.CellA, '.locus1(1).score');
            locus1_i = drill(data_c.CellA, '.locus1(1).intensity');
            
            locus2_L1 = drill(data_c.CellA, '.locus1(2).longaxis');
            locus2_L2 = drill(data_c.CellA, '.locus1(2).shortaxis');
            locus2_s = drill(data_c.CellA, '.locus1(2).score');
            locus2_i = drill(data_c.CellA, '.locus1(2).intensity');
            
            locus3_L1 = drill(data_c.CellA, '.locus1(3).longaxis');
            locus3_L2 = drill(data_c.CellA, '.locus1(3).shortaxis');
            locus3_s = drill(data_c.CellA, '.locus1(3).score');
            locus3_i = drill(data_c.CellA, '.locus1(3).intensity');
            
            locus4_L1 = drill(data_c.CellA, '.locus1(4).longaxis');
            locus4_L2 = drill(data_c.CellA, '.locus1(4).shortaxis');
            locus4_s = drill(data_c.CellA, '.locus1(4).score');
            locus4_i = drill(data_c.CellA, '.locus1(4).intensity');
            
            locus5_L1 = drill(data_c.CellA, '.locus1(5).longaxis');
            locus5_L2 = drill(data_c.CellA, '.locus1(5).shortaxis');
            locus5_s = drill(data_c.CellA, '.locus1(5).score');
            locus5_i = drill(data_c.CellA, '.locus1(5).intensity');
            
            daughter1_id = drill(data_c.regs.daughterID,'(1)');
            daughter2_id = drill(data_c.regs.daughterID,'(2)');
            mother_id    = data_c.regs.motherID;
           
            %Addition of score longaxisaxis channel 2
            locus1_L1_2 = drill(data_c.CellA, '.locus2(1).longaxis');
            locus2_L1_2 = drill(data_c.CellA, '.locus2(2).longaxis');
            locus3_L1_2 = drill(data_c.CellA, '.locus2(3).longaxis');
            locus4_L1_2 = drill(data_c.CellA, '.locus2(4).longaxis');
            
            %Addition of score shortaxis channel 2
            locus1_L2_2 = drill(data_c.CellA, '.locus2(1).shortaxis');
            locus2_L2_2 = drill(data_c.CellA, '.locus2(2).shortaxis');
            locus3_L2_2 = drill(data_c.CellA, '.locus2(3).shortaxis');
            locus4_L2_2 = drill(data_c.CellA, '.locus2(4).shortaxis');
            
            %Addition of score of spot channel 2 (561 nm)
            locus1_s2 = drill(data_c.CellA, '.locus2(1).score');
            locus2_s2 = drill(data_c.CellA, '.locus2(2).score');
            locus3_s2 = drill(data_c.CellA, '.locus2(3).score');
            locus4_s2 = drill(data_c.CellA, '.locus2(4).score');
            
            %Addition of spot intensity data channel 2 (561 nm)
            locus1_i2 = drill(data_c.CellA, '.locus2(1).intensity');
            locus2_i2 = drill(data_c.CellA, '.locus2(2).intensity');
            locus3_i2 = drill(data_c.CellA, '.locus2(3).intensity');
            locus4_i2 = drill(data_c.CellA, '.locus2(4).intensity');

            % get lineage stuff done here
            
            ind_tmp0 = (ID==0);

            
            if isempty( gen_ )
                prog =    ID;
                gen0 =  0*ID;
                gen  =  0*ID;
                
            else
                % copy info from previous IDs
                prog = nan( size( ID ) );
                gen0 = nan( size( ID ) );
                gen  = nan( size( ID ) );
                
                
                ind_tmp1 = and( ind_tmp0,~birthID_flag);
                ind_tmp2 = and( ~ind_tmp0,~birthID_flag);
                
                prog(ind_tmp2) = prog_(ID(ind_tmp2));
                gen0(ind_tmp2) = gen0_(ID(ind_tmp2));
                gen(ind_tmp2)  = gen_(ID(ind_tmp2));
                
                % Start this should never run
                if sum(ind_tmp0) > 0 
                    disp( [header, 'Clist frame: ',num2str(i), ...
                        ': ID = 0 detected! Possible tracking problems.'] );
                end
                
                prog(ind_tmp1) = 0;
                gen0(ind_tmp1) = 0;
                gen(ind_tmp1)  = 0;
                % End this should never run

                
                
                % now take care of new cells
                mother_list = mother_id(birthID_flag);
                
                prog_tmp = nan( size( mother_list ));
                gen0_tmp = nan( size( mother_list ));
                gen_tmp = nan( size( mother_list ));
                
                prog_tmp(mother_list>0) = prog_(mother_list(mother_list>0));
                gen0_tmp(mother_list>0) = gen0_(mother_list(mother_list>0))+1;
                gen_tmp(mother_list>0)  = gen_(mother_list(mother_list>0))+1;
                
                ID_ml = ID(birthID_flag);
                prog_tmp(mother_list==0) = ID_ml(mother_list==0);
                gen0_tmp(mother_list==0) = nan;
                gen_tmp(mother_list==0)  = 0;  
                
                prog(birthID_flag) = prog_tmp;
                gen0(birthID_flag) = gen0_tmp;
                gen(birthID_flag)  = gen_tmp;
            end
            
            IDmax = max(ID);
            
            gen0_(ID(~ind_tmp0)) = gen0(~ind_tmp0);
            gen_(ID(~ind_tmp0))  = gen(~ind_tmp0);
            prog_(ID(~ind_tmp0)) = prog(~ind_tmp0);
            % done lineage stuff.    
            
            length1 = drill(data_c.CellA,'.length(1)');
            length2 = drill(data_c.CellA,'.length(2)');
            
            locus1_relL1 = (locus1_L1)./length1;
            locus2_relL1 = (locus2_L1)./length1;
            locus3_relL1 = (locus3_L1)./length1;
            locus4_relL1 = (locus4_L1)./length1;
            locus5_relL1 = (locus5_L1)./length1;
            
            locus1_relL2 = (locus1_L2)./length2;
            locus2_relL2 = (locus2_L2)./length2;
            locus3_relL2 = (locus3_L2)./length2;
            locus4_relL2 = (locus4_L2)./length2;
            locus5_relL2 = (locus5_L2)./length2;
            op_ori =  drill(data_c.CellA, '.pole.op_ori');
            
            locus1_PoleAlign_L1 = locus1_L1 .* op_ori;
            locus1_PoleAlign_L1 (op_ori ==0) = nan;
            
            locus1_PoleAlign_relL1 = locus1_relL1 .* op_ori;
            locus1_PoleAlign_relL1 (op_ori==0) = nan;
            
            locus1_fitSigma  = drill(data_c.CellA,'.locus1(1).fitSigma');
            locus2_fitSigma  = drill(data_c.CellA,'.locus1(2).fitSigma');
            locus3_fitSigma  = drill(data_c.CellA,'.locus1(3).fitSigma');
            locus4_fitSigma  = drill(data_c.CellA,'.locus1(4).fitSigma');
            
           %Addition of gaussian fit to signal channel 2 (561 nm)
            locus1_fitSigma2 = drill(data_c.CellA, '.locus2(1).fitSigma');
            locus2_fitSigma2 = drill(data_c.CellA, '.locus2(2).fitSigma');
            locus3_fitSigma2 = drill(data_c.CellA, '.locus2(3).fitSigma');
            locus4_fitSigma2 = drill(data_c.CellA, '.locus2(4).fitSigma');

            
            lnew = data_c.regs.L1;
            dl = (lnew-lold);
            dlmin = nan(size(dl));
            dlmax = nan(size(dl));
            
            indTmp = isnan(dlminOld);
            dlmin( indTmp ) = dl(indTmp);
            
            indTmp = isnan(dlmaxOld);
            dlmax( indTmp ) = dl( indTmp);
            
            indTmp = isnan(dl);
            dlmin( indTmp ) = dlminOld( indTmp);
            dlmax( indTmp ) = dlmaxOld( indTmp);
            
            indTmp = ~isnan(dl+dlminOld);
            dlmin( indTmp ) = min( [dl(indTmp);dlminOld( indTmp )]);
            
            indTmp = ~isnan(dl+dlmaxOld);
            dlmax( indTmp ) = max( [dl( indTmp);dlmaxOld( indTmp )]);
            
            lrel = lnew./lbirth;
            
            longOverShort = data_c.regs.L1./data_c.regs.L2;
            neckWidth =  data_c.regs.info(:,3);
            maxWidth = data_c.regs.info(:,4);
            
            % putting all fields in tmp
            tmp = nan (numel(ID),numel(tmpFields));
            for u = 1 : numel(tmpFields)
                tmp_var =  eval(tmpFields{u});
                tmp_var = convertToColumn(tmp_var);
                tmp(:,u) = tmp_var;
            end
            
            % keeping from tmp only the cell that were just born
            try
                clist_tmp(ID(birthID_flag), : ) = tmp(birthID_flag, :);
                clist_3D(ID(ID_non_zero_flag), :, i ) = tmp(ID_non_zero_flag, clist3d_ind);
                
            catch ME
                printError(ME);
            end
            
            % update guys that you want to set to the death value
            clist_tmp(ID(ci), death_ind ) = tmp(ci, death_ind);
            
            if CONST.parallel.show_status
                waitbar(i/num_im,h,['Clist--Frame: ',num2str(i),'/',num2str(num_im)]);
            elseif CONST.parallel.verbose
                disp([header, 'Clist frame: ',num2str(i),' of ',num2str(num_im)]);
            end
        end
        
        
    end
    
    
    if CONST.parallel.show_status
        close(h);
    end
    
    % removes cells with 0 cell id
    clist.data   = clist_tmp(logical(clist_tmp(:,1)),:);
    clist.data3D = clist_3D(clist.data(:,1),:,:);


    clist = gateTool( clist, 'add3Dt' );
    
    % add channel max and min
    clist.imRangeGlobal = imRangeGlobal;

    
    %add3dtime stuff
    len_time_ind = grabClistIndex(clist, 'Long axis (L)', 1);
    
    ss = size( clist.data3D );
    if numel(ss) == 2
        ss(3) = 1;
    end
    len  = reshape( ~isnan(squeeze(clist.data3D(:,len_time_ind(1),:))),[ss(1),ss(3)]);
    age = cumsum( len, 2 );
    age(~len) = nan;
    
    % Add time, age and relative age to 3D clist.
    clist = gateTool( clist, 'add3Dt' );
    
    % Add growth rate to 3D Clist.
    len_0_ind = grabClistIndex(clist, 'Long axis (L) birth');
    len_0 = clist.data(:,len_0_ind);
    len_1_ind = grabClistIndex(clist, 'Long axis (L) death');
    len_1 = clist.data(:,len_1_ind);
    age_ind = grabClistIndex(clist, 'Cell age');
    age = clist.data(:,age_ind);
    growth_rate = (log(len_1) - log(len_0)) ./ age;
    clist = gateTool( clist, 'add', growth_rate, 'Growth Rate' );
    
    clist.gate = CONST.trackLoci.gate;
    clist.neighbor = [];
    
    if CONST.trackOpti.NEIGHBOR_FLAG
        clist.neighbor = trackOptiListNeighbor(dirname,CONST,[]);
    end
end
end


function [setter,names_3dclist] = clistSetter ()
% clistSetter : use this function to add new values to the clist
% the first variable is the description, the second is the variabel to
% which it will be set (needs to be calculated in the first function, and
% the third is 0 if it is set at birth and 1 if it is set at death.
% the fourth column is for whether the variable should be included in the 3d clist.

setter = [{'Cell ID'},{'ID'},0,1;                                   %1
    {'Region num birth'},{'regnum'},0,0;                            %2
    {'Region num death'},{'regnum'},1,0;                            %3
    {'Cell birth time'},{'i + zz'},0,0;                             %4
    {'Cell death time'},{'i + zz'},1,0;                             %5
    {'Cell age'},{'i - data_c.regs.birth'},1,0;                     %6
    {'Old pole age'},{'pole_age'},0,0;                              %7
    {'Error frame'},{'error_frame'},1,0;                            %8
    {'stat0'},{'data_c.regs.stat0'},1,0;                            %9
    {'Long axis (L) birth'},{'data_c.regs.L1'},0,1;                 %10
    {'Long axis (L) death'},{'data_c.regs.L1'},1,0;                 %11
    {'Short axis birth'},{'data_c.regs.L2'},0,1;                    %12
    {'Short axis death'},{'data_c.regs.L2'},1,0;                    %13
    {'Area birth'},{'Area'},0,1;                                    %14
    {'Area death'},{'Area'},1,0;                                    %15
    {'Region score birth'},{'data_c.regs.scoreRaw'},0,0;            %16
    {'Region score death'},{'data_c.regs.scoreRaw'},1,0;            %17
    {'X position birth'},{'xpos'},0,0;                              %18
    {'Y position birth'},{'ypos'},0,0;                              %19
    {'Fluor1 sum'},{'fl1sum'},0,1;                                  %20
    {'Fluor1 mean'},{'fl1sum./Area'},0,1;                           %21
    {'Fluor2 sum'},{'fl2sum'},0,1;                                  %22
    {'Fluor2 mean'},{'fl2sum./Area'},0,1;                           %23
    {'Num of neighbors'},{'numNeighbors'},0,0;                      %24
    {'Region gray val'},{'gray'},0,0;                               %25
    {'Focus1(1) long axis birth'},{'locus1_L1'},0,1;                %26
    {'Focus1(1) short axis birth'},{'locus1_L2'},0,1;               %27
    {'Focus1(1) score birth'},{'locus1_s'},0,1;                     %28
    {'Focus1(1) intensity birth'},{'locus1_i'},0,1;                 %29
    {'Focus1(2) long axis birth'},{'locus2_L1'},0,1;                %30
    {'Focus1(2) short axis birth'},{'locus2_L2'},0,1;               %31
    {'Focus1(2) score birth'},{'locus2_s'},0,1;                     %32
    {'Focus1(2) intensity birth'},{'locus2_i'},0,1;                 %33
    {'Focus1(3) long axis birth'},{'locus3_L1'},0,0;                %34
    {'Focus1(3) short axis birth'},{'locus3_L2'},0,0;               %35
    {'Focus1(3) score birth'},{'locus3_s'},0,0;                     %36
    {'Focus1(3) intensity birth'},{'locus3_i'},0,0;                 %37
    {'Focus1(4) long axis birth'},{'locus4_L1'},0,0;                %38
    {'Focus1(4) short axis birth'},{'locus4_L2'},0,0;               %39
    {'Focus1(4) score birth'},{'locus4_s'},0,0;                     %40
    {'Focus1(4) intensity birth'},{'locus4_i'},0,0;                 %41
    {'Focus1(5) long axis birth'},{'locus5_L1'},0,0;                %42
    {'Focus1(5) short axis birth'},{'locus5_L2'},0,0;               %43
    {'Focus1(5) score birth'},{'locus5_s'},0,0;                     %44
    {'Focus1(5) intensity birth'},{'locus5_i'},0,0;                 %45
    {'Focus1(1) long axis pole align'},{'locus1_PoleAlign_L1'},0,1; %46
    {'Focus1(1) long axis norm pole align'},{'locus1_PoleAlign_relL1'},0,1; %47
    {'Focus1(1) long axis normalized'},{'locus1_relL1'},0,0;        %48
    {'Focus1(2) long axis normalized'},{'locus2_relL1'},0,0;        %49
    {'Focus1(3) long axis normalized'},{'locus3_relL1'},0,0;        %50
    {'Focus1(4) long axis normalized'},{'locus4_relL1'},0,0;        %51
    {'Focus1(5) long axis normalized'},{'locus5_relL1'},0,0;        %52
    {'Focus1(1) short axis normalized'},{'locus1_relL2'},0,0;       %53
    {'Focus1(2) short axis normalized'},{'locus2_relL2'},0,0;       %54
    {'Focus1(3) short axis normalized'},{'locus3_relL2'},0,0;       %55
    {'Focus1(4) short axis normalized'},{'locus4_relL2'},0,0;       %56
    {'Focus1(5) short axis normalized'},{'locus5_relL2'},0,0;       %57
    {'Focus1(1) gaussianFitWidth'},{'locus1_fitSigma'},0,0;         %58
    {'Focus1(2) gaussianFitWidth'},{'locus2_fitSigma'},0,0;         %59
    {'Focus1(3) gaussianFitWidth'},{'locus3_fitSigma'},0,0;         %60
    {'Focus1(4) gaussianFitWidth'},{'locus4_fitSigma'},0,0;         %61
    {'Mother ID'},{'data_c.regs.motherID'},0,0;                     %62
    {'Daughter1 ID'},{'daughter1_id'},1,0;                          %63
    {'Daughter2 ID'},{'daughter2_id'},1,0;                          %64
    {'dL max'},{'dlmax'},1,0;                                       %65
    {'dL min'},{'dlmin'},1,0;                                       %66
    {'L death / L birth'},{'lrel'},1,0;                             %67
    {'Fluor1 sum death'},{'fl1sum'},1,0;                            %68
    {'Fluor1 mean death'},{'fl1sum./Area'},1,0;                     %69
    {'Fluor2 sum death'},{'fl2sum'},1,0;                            %70
    {'Fluor2 mean death'},{'fl2sum./Area'},1,0;                     %71
    {'Focus1(1) long axis death'},{'locus1_L1'},1,0;                %72
    {'Focus1(1) short axis death'},{'locus1_L2'},1,0;               %73
    {'Focus1(1) score death'},{'locus1_s'},1,0;                     %74
    {'Focus1(1) intensity death'},{'locus1_i'},1,0;                 %75
    {'Focus1(2) long axis death'},{'locus2_L1'},1,0;                %76
    {'Focus1(2) short axis death'},{'locus2_L2'},1,0;               %77
    {'Focus1(2) score death'},{'locus2_s'},1,0;                     %78
    {'Focus1(2) intensity death'},{'locus2_i'},1,0;                 %79
    {'Focus1(2) long axis death'},{'locus3_L1'},1,0;                %80
    {'Focus1(3) short axis death'},{'locus3_L2'},1,0;               %81
    {'Focus1(3) score death'},{'locus3_s'},1,0;                     %82
    {'Focus1(3) intensity death'},{'locus3_i'},1,0;                 %83
    {'Focus1(4) long axis death'},{'locus4_L1'},1,0;                %84
    {'Focus1(4) short axis death'},{'locus4_L2'},1,0;               %85
    {'Focus1(4) score death'},{'locus4_s'},1,0;                     %86
    {'Focus1(4) intensity death'},{'locus4_i'},1,0;                 %87
    {'Focus1(5) long axis death'},{'locus5_L1'},1,0;                %88
    {'Focus1(5) short axis death'},{'locus5_L2'},1,0;               %89
    {'Focus1(5) score death'},{'locus5_s'},1,0;                     %90
    {'Focus1(5) intensity death'},{'locus5_i'},1,0;                 %91
    {'Focus1(1) gaussian fit width death'},{'locus1_fitSigma'},1,0; %92
    {'Focus1(2) gaussian fit width death'},{'locus2_fitSigma'},1,0; %93
    {'Focus1(3) gaussian fit width death'},{'locus3_fitSigma'},1,0; %94
    {'Long axis/Short axis birth'},{'longOverShort'},0,0;           %95
    {'Long axis/Short axis death'},{'longOverShort'},1,0;           %96
    {'Neck width'},{'neckWidth'},0,0;                               %97
    {'Maximum width'},{'maxWidth'},0,0;                             %98
    {'Cell dist to edge'},{'cell_dist'},1,0;                        %99
    {'Generation'},{'gen'},0,0;                                     %100
    {'Generation0'},{'gen0'},0,0;                                   %101
    {'Progenitor'},{'prog'},0,0;                                    %102
    {'Focus2(1) intensity birth'},{'locus1_i2'},0,0;                        %103 added for 2nd fluor channel plotting 103-110
    {'Focus2(2) intensity birth'},{'locus2_i2'},0,0;                        %104
    {'Focus2(3) intensity birth'},{'locus3_i2'},0,0;                        %105
    {'Focus2(4) intensity birth'},{'locus4_i2'},0,0;                        %106
    {'Focus2(1) gaussianFitWidth'},{'locus1_fitSigma2'},0,0;                %107
    {'Focus2(2) gaussianFitWidth'},{'locus2_fitSigma2'},0,0;                %108
    {'Focus2(3) gaussianFitWidth'},{'locus3_fitSigma2'},0,0;                %109
    {'Focus2(4) gaussianFitWidth'},{'locus4_fitSigma2'},0,0;                %110
    {'Focus2(1) long axis birth'},{'locus1_L1_2'},0,0;                      %111
    {'Focus2(2) long axis birth'},{'locus2_L1_2'},0,0;                      %112
    {'Focus2(3) long axis birth'},{'locus3_L1_2'},0,0;                      %113
    {'Focus2(4) long axis birth'},{'locus4_L1_2'},0,0;                      %114
    {'Focus2(1) short axis birth'},{'locus1_L2_2'},0,0;                     %115
    {'Focus2(2) short axis birth'},{'locus2_L2_2'},0,0;                     %116
    {'Focus2(3) short axis birth'},{'locus3_L2_2'},0,0;                     %117    
    {'Focus2(4) short axis birth'},{'locus4_L2_2'},0,0;                     %118
    ];


% used to add numbers in front of the description
counter = 0;
num_3d_clist = sum([setter{:,4}]);
names_3dclist = cell(1,num_3d_clist);
for i = 1 : size(setter,1)
    fieldname = setter{i,1};
    nameWithNum = [num2str(i), ' : ',fieldname];
    setter(i,1) = {nameWithNum};
    if setter{i,4}
        counter = counter + 1;
        removeBirth = strfind(fieldname,'birth');
        if removeBirth > 0
            fieldname = fieldname (1 :removeBirth-1);
        end
        names_3dclist{counter} = [num2str(counter), ' : ', fieldname];
    end
end
end


function vector = convertToColumn (vector)
% convertToColumn : converts vector to column vector if row vector
if size(vector,1) == 1
    vector = vector';
end
end

function data = loaderInternal( filename )
data = load(filename);
end
