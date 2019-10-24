classdef DrawLink < handle
    
    properties
        
        lanegroups @DrawLaneGroup
        link_length
        patches     % array of patches
    end
    
    methods(Access=public)
        
        function [this] = DrawLink(link)
            if nargin>0
                this.link_length = link.full_length;
            end
        end
     
        function [this] = draw(this,link,java_lanegroups,lanewidth)
                        
            geom = Geom(link);
            
            points = link.shape;
            
            %  segment info
            segments = DrawLink.extract_segments(points);
                        
            %  scale segement lengths
%             scale_factor = this.link_length / sum([segments.length]);
%             if abs(scale_factor-1) > 0.05
%                 error('Geometric error is too large')
%             end
            % alternatively you can scale:
%             for i=1:numel(segments)
%                 segments(i).start_p = segments(i).start_p * scale_factor;
%                 segments(i).end_p = segments(i).end_p * scale_factor;
%                 segments(i).length = segments(i).length * scale_factor;
%             end
            
            % array of lanegroup objects
            num_lanegroup = numel(java_lanegroups);
            this.lanegroups(1:num_lanegroup) = DrawLaneGroup;
            for i=1:num_lanegroup
                lg = java_lanegroups(i);
                this.lanegroups(i) = DrawLaneGroup(lg,lanewidth,geom);
            end
            
            % compute total width ................................
            total_lanes = geom.get_num_total_lanes; % DrawLink.compute_total_lanes();
            total_width = total_lanes * lanewidth;

            % map lanes to lanegroup
            lane2lanegoupid = nan(1,total_lanes);
            for lane=1:total_lanes
                ind = arrayfun(@(z) ismember(lane,z.lanes),this.lanegroups);
                if sum(ind)~=1
                    error('sum(ind)~=1')
                end
                lane2lanegoupid(lane) = this.lanegroups(ind).id;
            end
            
            % calculate color for each lane
            numcolors = 2;
            c = cumsum([1 diff(lane2lanegoupid)~=0]);
            lane2color = nan*lane2lanegoupid;
            for i=1:numel(lane2color)
                lane2color(i) = mod(c(i)-1,numcolors);
            end
            clear c

            % initialize offset and start_lane ....................
            lane_one_offset = -total_width/2;
            
            % draw each lanegroup
            for i=1:num_lanegroup
                this.lanegroups(i).draw(segments,lane_one_offset,lanewidth,lane2color)
            end            

        end
        
    end
    
    methods(Access=private,Static)
        
        function [segments] = extract_segments(points)
            
            segments = repmat(struct('start_p',[],'end_p',[],'length',nan,'d',[],'n_start',[],'n_end',[]),1,numel(points)-1);
            for i=1:numel(points)-1
                this_point = points(i);
                next_point = points(i+1);
                segments(i).start_p = [this_point.x this_point.y];
                segments(i).end_p = [next_point.x next_point.y];
                segments(i).length = norm(segments(i).end_p-segments(i).start_p);
                segments(i).d = (segments(i).end_p-segments(i).start_p)/norm(segments(i).end_p-segments(i).start_p);
            end
            clear n
            for i=1:numel(segments)
                n_prev = DrawLink.normal_vector(segments(max([i-1,1])).d);
                n_this = DrawLink.normal_vector(segments(i).d);
                n_next = DrawLink.normal_vector(segments(min([i+1,numel(segments)])).d);
                segments(i).n_start = mean([n_prev;n_this]);
                segments(i).n_end = mean([n_next;n_this]);
            end
            
        end
        
%         function [h]=plot_line_for_points(segments,offset,start_at,end_at,width,lanecolors)
%             
%             cum_length = cumsum([segments.length]);
%             
%             start_segment = find(start_at<=cum_length,1,'first');
%             end_segment = find(end_at<=cum_length,1,'first');
%             if isempty(end_segment)
%                 end_segment=numel(segments);
%             end
%             
%             if start_segment>1
%                 draw_start = start_at - cum_length(start_segment-1);
%             else
%                 draw_start = start_at;
%             end
%             remains = end_at-start_at;
%             for ii=start_segment:end_segment
%                 seg = segments(ii);
%                 
%                 draw_length = min([remains segments(ii).length-draw_start]);
%                 
%                 % start points
%                 P = seg.start_p + seg.d * draw_start;
%                 nP = DrawLink.interpolate_normal(seg.n_start,seg.n_end,draw_start,seg.length);
%                 d = DrawLink.distance_to_offset(seg.d,nP,offset);
%                 a1 = P + nP*d;
%                 a2 = P + nP*(d+width);
%                 
%                 % end points
%                 P = P + seg.d * draw_length;
%                 nP = DrawLink.interpolate_normal(seg.n_start,seg.n_end,draw_start+draw_length,seg.length);
%                 d = DrawLink.distance_to_offset(seg.d,nP,offset);
%                 a3 = P + nP*(d+width);
%                 a4 = P + nP*d;
%                 
%                 % patch
%                 p = [a1;a2;a3;a4];
%                 h(ii) = patch('XData',p(:,1),'YData',p(:,2));
%                 hold on
%                 
%                 remains = remains - draw_length;
%                 draw_start = 0;
%                 
%                 if remains<1e-4
%                     break
%                 end
%                 
%             end
%             
%         end
        
        function n=normal_vector(d)
            n = cross([d 0],[0 0 1]);
            n = n(1:2);
        end
        
        
%         function [total_lanes]=compute_total_lanes(geom)
%             total_lanes = geom.lanes;
%             if ~isempty(geom.left_addlane)
%                 total_lanes = total_lanes + max(arrayfun(@(z) z.ATTRIBUTE.lanes,geom.left_addlane));
%             end
%             if ~isempty(geom.right_addlane)
%                 total_lanes = total_lanes + max(arrayfun(@(z) z.ATTRIBUTE.lanes,geom.right_addlane));
%             end
%         end
        
    end
   
end

