function [C_C , C_R ] = cost_function_final ( b , server, router , Cost_R , Cost_C ,N)



evaluated_costs = 1:4194304;

Sub_1 = ones(4194304,4);
Sub_2 = ones(4194304,11);

% count = 0;

for It = N'

    % count = count + 1;

    [H{1:11}] = ind2sub(server.jobs * ones(1 , 11) , It);
    A = cell2mat(H);

    Sub_1( It , :) = b+1;
    Sub_2( It , :) = A;

end

possible_actions = [router.jobs router.jobs router.jobs router.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs];

Sub_total = [Sub_1 , Sub_2];

input_index = sub2ind (possible_actions , Sub_total (:,1) , Sub_total (:,2) , Sub_total (:,3) ,...
    Sub_total (:,4) , Sub_total (:,5) , Sub_total (:,6), Sub_total (:,7), Sub_total (:,8), Sub_total (:,9),...
    Sub_total (:,10), Sub_total (:,11), Sub_total (:,12), Sub_total (:,13), Sub_total (:,14), Sub_total (:,15));

C_C = Cost_C( input_index );
C_R = Cost_R( input_index );

end