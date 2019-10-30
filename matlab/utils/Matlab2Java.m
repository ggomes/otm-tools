function [ J ] = Matlab2Java( M , c )

switch c
    
    case 'Float'
        J = java.lang.Float(M);
    
    case 'Long'
        J = java.lang.Long(M);
        
    case 'Boolean'
        J = java.lang.Boolean(M);
        
    case 'FloatList'
        J = java.util.ArrayList;
        for i=1:numel(M)
            J.add(java.lang.Float(M(i)));
        end
         
    case 'LongList'
        J = java.util.ArrayList;
        for i=1:numel(M)
            J.add(java.lang.Long(M(i)));
        end
        
    case 'FloatSet'
        J = java.util.HashSet;
        for i=1:numel(M)
            J.add(java.lang.Float(M(i)));
        end
        
    case 'LongSet'
        J = java.util.HashSet;
        for i=1:numel(M)
            J.add(java.lang.Long(M(i)));
        end
       
    otherwise
        error(['unsupported type ' c])
        
end
