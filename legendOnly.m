function[f]=legendOnly(odor_conc_inf,odor_inf)
     1;
     f=figure;
     odor_list=odor_inf.odor_list;
     odor_concentration_list=odor_inf.odor_concentration_list;
     odor_colormap=odor_inf.odor_colormap;
     not_water=~strcmp(odor_conc_inf(:,2),'water');
     t_cum=[0,cumsum([odor_conc_inf{:,3}])];
     
     conc_id=cellfun(@(x)find(strcmp(odor_concentration_list,x)),odor_conc_inf(not_water,1));
     odor_id=cellfun(@(x)find(strcmp(odor_list,x)),odor_conc_inf(not_water,2));
     odor_starts=t_cum(not_water);
     odor_ends=t_cum(find(not_water)+1);
     odor_conc_id = (odor_id-1)*length(odor_concentration_list)+conc_id;
     color_seq = odor_colormap(odor_conc_id,:);
     x=[0,1,1,0];
        y=[0,1,1,0];
     for ii=1:length(odor_starts)
        
        patches(ii)=patch(x,y,color_seq(ii,:),...
            'EdgeColor','none','FaceAlpha',0.4);
        hold on;        
     end
    odor_conc_str=cellfun(@(x,y)strtrim(sprintf('%s %s',x,y)),odor_conc_inf(:,1),...
        odor_conc_inf(:,2),'UniformOutput',false);
        [leg,BLicons]=legend(patches,odor_conc_str(not_water));
        PatchInLegend = findobj(BLicons, 'type', 'patch');
        set(PatchInLegend, 'facea', 0.4)
        ax=gca;
        ax.Visible='Off';
        leg.Units='pixels';
        f.Units='pixels';
        f.Position=leg.Position;
        f.Position(3:4)=leg.Position(3:4)*1.2;
        leg.Location='best';
        f.MenuBar='none';
        f.Name='Odors';