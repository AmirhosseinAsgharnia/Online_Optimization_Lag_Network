function [C_C , C_R , evaluated_costs] = cost_function ( b , Repeat_a , server, router, Cost_R , Cost_C)

max_tests = 1000;

r_a   = sum(Repeat_a , 2);
a_ind = find(r_a ~= 0);

[H{1 : 11}] = ind2sub (server.jobs * ones(1 , 11) , a_ind);
A_n = flip(cell2mat(H) , 2);

num_A_n = size(A_n , 1);

A_n_p = randi([1 server.jobs] , max_tests - num_A_n , 11);

B_n = [A_n ; A_n_p];

a_max_ind = sub2ind(server.jobs * ones(1 , 11) , B_n(:,11) , B_n(:,10) , B_n(:,9) , B_n(:,8) , B_n(:,7) , B_n(:,6) , B_n(:,5) , B_n(:,4) , B_n(:,3) , B_n(:,2) , B_n(:,1) );

evaluated_costs = a_max_ind;

Sub_1 = zeros(numel(a_max_ind) , 4);
Sub_2 = zeros(numel(a_max_ind) , 11);

count = 0;

for It = evaluated_costs'

    count = count + 1;

    [H{1:11}] = ind2sub(server.jobs * ones(1 , 11) , It);
    A = cell2mat(H);

    Sub_1( count , :) = b+1;
    Sub_2( count , :) = A;

end

possible_actions = [router.jobs router.jobs router.jobs router.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs server.jobs];

Sub_total = [Sub_1 , Sub_2];

input_index = sub2ind (possible_actions , Sub_total (:,1) , Sub_total (:,2) , Sub_total (:,3) ,...
    Sub_total (:,4) , Sub_total (:,5) , Sub_total (:,6), Sub_total (:,7), Sub_total (:,8), Sub_total (:,9),...
    Sub_total (:,10), Sub_total (:,11), Sub_total (:,12), Sub_total (:,13), Sub_total (:,14), Sub_total (:,15));

C_C = Cost_C( input_index );
C_R = Cost_R( input_index );

end