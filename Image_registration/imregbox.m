function [green_stack_aligned, red_stack_aligned]=...
    imregbox(red_img, green_img,varargin)
%does a box filter on movie, uses that for registration - reduces file size
if any(strcmp(varargin,'scalexy'))
    scalexy=varargin{find(strcmp(varargin,'scalexy'))+1};
else
    scalexy=29;    
end
if any(strcmp(varargin,'scalez'))
    scalez=varargin{find(strcmp(varargin,'scalez'))+1};
else
    scalez=5;
end
if any(strcmp(varargin,'maxiter'))
    maxiter=varargin{find(strcmp(varargin,'maxiter'))+1};
else
    maxiter=1000;
end
if any(strcmp(varargin,'minstep'))
    minstep=varargin{find(strcmp(varargin,'minstep'))+1};
else
    minstep=1e-6;
end
if any(strcmp(varargin,'maxstep'))
    maxstep=varargin{find(strcmp(varargin,'maxstep'))+1};
else
    maxstep=.0625;
end
if any(strcmp(varargin,'scalexy pass 2'))
    scalexy2=varargin{find(strcmp(varargin,'scalexy pass 2'))+1};
else
    scalexy2=5;
end
if any(strcmp(varargin,'doublepass'))
    doublepass=varargin{find(strcmp(varargin,'doublepass'))+1};
else
    doublepass=2;
end
if any(strcmp(varargin,'crop'))
    crop=varargin{find(strcmp(varargin,'crop'))+1};
else
    crop=1;
end

%% 
scaleview=round(scalexy/2);
scaleviewz=round(scalez/2);
red_stack_filt=box_filt4D(red_img,[scalexy,scalexy,scalez]);
red_stack_sub=red_stack_filt(1:scaleview:end,1:scaleview:end,1:scaleviewz:end,:);


optimizer = registration.optimizer.RegularStepGradientDescent;
[optimizer, metric]  = imregconfig('monomodal');
MaxStepLength_init=maxstep;
optimizer.MaximumIterations=maxiter;
optimizer.MinimumStepLength=minstep;
%% 

fixed=red_stack_sub(:,:,:,1);

red_stack_max=squeeze(max(red_img,[],3));
fixed_max=red_stack_max(:,:,1);

h=waitbar(0,'Running Registration');
tform_scaled=cell(size(red_img,4),1);
img_size=size(red_stack_filt(:,:,:,1));

green_stack_aligned=zeros(size(green_img));
green_stack_aligned(:,:,:,1)=green_img(:,:,:,1);
red_stack_aligned=zeros(size(red_img));
red_stack_aligned(:,:,:,1)=red_img(:,:,:,1);
tic
for ii=2:size(red_img,4)
    
    moving=red_stack_sub(:,:,:,ii);
    tform = imregtform(moving,fixed,'translation',...
        optimizer,metric,'DisplayOptimization',false,'PyramidLevels',1);
    [~,lastwarning]=lastwarn;
    while strcmp(lastwarning,'images:regmex:registrationOutBoundsTermination')
       lastwarn(''); 
       optimizer.MaximumStepLength = optimizer.MaximumStepLength/2;
       tform = imregtform(moving,fixed,'translation',...
        optimizer,metric,'DisplayOptimization',false,'PyramidLevels',1);
       [~,lastwarning]=lastwarn;
    end
    optimizer.MaximumStepLength = MaxStepLength_init;
    
    
    tform_scaled{ii}=tform;
    if length(size(fixed))==2
    
    %tform_scaled{ii}.T=tform.T*tform_scale.T;
    
        tform_scaled{ii}.T(3,1:2)=tform_scaled{ii}.T(3,1:2)*scaleview;
        red_stack_aligned(:,:,:,ii)=imwarp(red_img(:,:,:,ii),tform_scaled{ii},...
            'OutputView',imref2d(img_size));
        red_sub_aligned(:,:,:,ii)=imwarp(red_stack_sub(:,:,:,ii),tform,...
            'OutputView',imref2d(size(red_stack_sub(:,:,:,1))));
     green_stack_aligned(:,:,:,ii)=imwarp(green_img(:,:,:,ii),tform_scaled{ii},...
            'OutputView',imref2d(img_size));
    else
        tform_scaled{ii}.T(4,1:2)=tform_scaled{ii}.T(4,1:2)*scaleview;
        tform_scaled{ii}.T(4,3)=tform_scaled{ii}.T(4,3)*scaleviewz;
        red_stack_aligned(:,:,:,ii)=imwarp(red_img(:,:,:,ii),tform_scaled{ii},...
            'OutputView',imref3d(img_size));
        red_sub_aligned(:,:,:,ii)=imwarp(red_stack_sub(:,:,:,ii),tform,...
            'OutputView',imref3d(size(red_stack_sub(:,:,:,1))));
     
        green_stack_aligned(:,:,:,ii)=imwarp(green_img(:,:,:,ii),tform_scaled{ii},...
            'OutputView',imref3d(img_size));
    end   
    waitbar(ii/(2*size(red_img,4)),h);
end

min_red_stack_aligned=min(red_stack_aligned,[],4);
idx=find(min_red_stack_aligned~=0);
[i,j,k]=ind2sub(size(min_red_stack_aligned),idx);
red_stack_cropped=box_filt4D(red_stack_aligned(min(i):max(i),min(j):max(j),min(k):max(k),:),...
    [scalexy2,scalexy2,1]);
green_stack_cropped=green_stack_aligned(min(i):max(i),min(j):max(j),min(k):max(k),:);
red_stack_cropped_max=squeeze(max(red_stack_cropped,[],3));
fixed_max=red_stack_cropped_max(:,:,1);
red_stack_aligned=red_stack_cropped;
green_stack_aligned=green_stack_cropped;
if doublepass==2
    if crop
     f=figure;
     imagesc(max(red_stack_cropped_max,[],3));
     title('Select ROI')
     crop2=getrect;
     rng_i=round(crop2(2):crop2(2)+crop2(4));
     rng_j=round(crop2(1):crop2(1)+crop2(3));
     red_stack_cropped=red_stack_cropped(rng_i,rng_j,:,:);
     green_stack_cropped=green_stack_cropped(rng_i,rng_j,:,:);
%     [red_stack_cropped_max,xrange,yrange]=crop_img(max(red_stack_cropped_max,[],3));
%     red_stack_aligned=red_stack_aligned(yrange,xrange,:,:);
%     green_stack_aligned=green_stack_aligned(yrange,xrange,:,:);
    close(f);
    end
  %  if size(red_stack_cropped,3)>1
        red_stack_cropped_max=squeeze(max(red_stack_cropped,[],3));
  %  else
%        red_stack_cropped_max=red_stack_cropped;
 %   end
     fixed_max=red_stack_cropped_max(:,:,1);
    red_stack_aligned=red_stack_cropped;
    green_stack_aligned=green_stack_cropped;
    
    for ii=2:size(red_stack_aligned,4)
        waitbar(0.5+ii/(2*size(red_img,4)),h);
        moving_max=red_stack_cropped_max(:,:,ii);
        tform = imregtform(moving_max,fixed_max,'translation',...
            optimizer,metric,'DisplayOptimization',false,'PyramidLevels',3);
        [~,lastwarning]=lastwarn;
        while strcmp(lastwarning,'images:regmex:registrationOutBoundsTermination')
           lastwarn(''); 
           optimizer.MaximumStepLength = optimizer.MaximumStepLength/2;
           tform = imregtform(moving,fixed,'translation',...
            optimizer,metric,'DisplayOptimization',false,'PyramidLevels',1);
           [~,lastwarning]=lastwarn;
        end
        optimizer.MaximumStepLength = MaxStepLength_init;
        if length(size(moving_max))==2
            try
            red_stack_aligned(:,:,:,ii)=imwarp(red_stack_cropped(:,:,:,ii),tform,...
            'OutputView',imref2d(size(red_stack_cropped_max(:,:,1)))); 
            catch
                1;
            end
            green_stack_aligned(:,:,:,ii)=imwarp(green_stack_cropped(:,:,:,ii),tform,...
             'OutputView',imref2d(size(red_stack_cropped_max(:,:,1))));
        else
            T3D=eye(4);
            T3D(4,1:2)=tform.T(3,1:2);
            tform3d=affine3d(T3D);

            red_stack_aligned(:,:,:,ii)=imwarp(red_stack_cropped(:,:,:,ii),tform3d,...
                'OutputView',imref3d(size(red_stack_cropped(:,:,:,1)))); 
            green_stack_aligned(:,:,:,ii)=imwarp(green_stack_cropped(:,:,:,ii),tform3d,...
                'OutputView',imref3d(size(red_stack_cropped(:,:,:,1)))); 
        end
    end
end
min_red_stack_aligned=min(red_stack_aligned,[],4);
idx=find(min_red_stack_aligned~=0);
[i,j,k]=ind2sub(size(min_red_stack_aligned),idx);
red_stack_aligned = red_stack_aligned(min(i):max(i),min(j):max(j),min(k):max(k),:);
green_stack_aligned=green_stack_aligned(min(i):max(i),min(j):max(j),min(k):max(k),:);

green_stack_aligned=gpu_medfilt4( green_stack_aligned,'green',2,0);
red_stack_aligned=gpu_medfilt4(red_stack_aligned,'red',2,0);

toc
close(h)