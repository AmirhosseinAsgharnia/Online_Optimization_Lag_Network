function [distance_vector , distance_index , G] = network_analysis ()
%%

gateway_router = [1 2 3 4]'; % 4  nodes
network_router = [5 6 7 8]'; % 4  nodes
servers        = (9:19)';      % 11 nodes

%%
source = [1  1   2   2   3   3   4   4   5   5   5   6   6   7   7   7   8   8   9   9   9   10   10];
target = [2  16  11  12  17  18  18  19  9   16  17  9   15  8   14  18  13  19  10  11  14  12   13];
weight = 1*[10 1   1   1   1   1   1   1   10  1   10  1   1   1   1   1   1   1   10  10  10  1    10];
G = graph(source , target , weight);

%%

distance_nums  = numel (gateway_router) * numel (servers);

distance_index = zeros (distance_nums , 2);

distance_vector = zeros (distance_nums , 1);

i = 1;

for source_index = gateway_router'

    for sink_index = servers'

        [ ~ , dist ] = shortestpath(G , source_index , sink_index);

        distance_index  (i , :) = [source_index , sink_index];

        distance_vector (i , :) = dist;
        
        i = i + 1;

    end

end

[distance_vector , distance_vector_sort_index] = sort (distance_vector);
distance_index = distance_index(distance_vector_sort_index , :);