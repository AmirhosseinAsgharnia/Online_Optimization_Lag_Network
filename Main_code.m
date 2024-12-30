clear; clc
%%

load("Four_node.mat")
load("Cost_Metro_Network.mat")
load("FT_3.mat")
FT_3 = FT;
load("FT_4.mat")
FT_4 = FT;
load("so.mat")
%%

b(:,1) = 1;
b(:,2) = 2;
b(:,3) = 0;
b(:,4) = 1;
%% Time

time_horizon = 20000; % (T)
T_M = 500 * ones(1); % Look back time. T_M is used to measure the importance of a reservation based on previous T_M repeat.

%%
Expected_reserve = zeros(time_horizon , 1 , 'single');
Expected_block   = zeros(time_horizon , 1 , 'single');
%% Core Hyper Parameters

lambda = 25; % Lagrange multiplier (\lambda)
eta    = sqrt(1/T_M); % (\eta)
v      = 10; % Blocking cost threshold (v)
epsilon= 0.0; % Exploration rate (\varepsilon)
Beta_LR= .1; % Learning rate (\beta)

%% Estimator's Hyper Parameters (Router)

router.num                  = 4; % Number of gateway routers
router.jobs                 = 5;
router.num_MF               = 3;
router.num_rules            = router.num_MF ^ router.num;
router.input_bounds         = ones (router.num , 2 , 'uint8');
router.input_bounds(: , 2)  = router.jobs;

router.rule_base            = zeros (router.num_rules , 1);

%% Estimator's Hyper Parameters (Server)

server.num                  = 11;
server.jobs                 = 4; % Possible reservations. Action 1: 0 reservations / Action 2: 1 resersavtion / ... / Action 5: 4 reservations
server.job_vector           = server.jobs * ones( 1 , server.num ); 
server.num_possible_actions = prod ( server.job_vector );
server.num_MF               = 3;
server.num_rules            = server.num_MF ^ server.num;
server.input_bounds         = ones (server.num , 2);
server.input_bounds(: , 2)  = server.jobs;

server.rule_base_R          = ones (server.num_rules , 1) / server.num_rules;
server.rule_base_C          = ones (server.num_rules , router.num_rules) / server.num_rules;
server.probability          = zeros (time_horizon , 1);
% server.P                    = zeros (server.num_rules , time_horizon);
probability_aux_normalized_pre = ones(server.num_rules , 1) / server.num_rules;
%%

% f_t = zeros( server.num_rules , T_M);
F_S = zeros( server.num_rules , T_M);
% 
% Repeat_b = zeros(num_rules , T_M);
Repeat_a = zeros(server.num_rules , T_M , 'uint8');

%%

tic;
rng(111)

W = ones(server.num_rules , T_M , 'single');

P1 = zeros (server.num_rules , 1);
P2 = zeros (server.num_possible_actions , 1);

A  = zeros( time_horizon , 11 , 'uint8');
for It = 1 : time_horizon

    if It ~= 1

        [C , R , evaluated_costs] = cost_function ( b (It - 1 , :) , Repeat_a , server, router , Cost_R , Cost_C);

        counter_1 = 0;

        for evaluate_input = evaluated_costs'

            counter_1 = counter_1 + 1;
            [H{1:server.num}] = ind2sub( server.jobs * ones(1 , server.num) , evaluate_input);
            A_eval = cell2mat(H);

            fuzzy_ind_router  = fuzzy_engine_4 (b(It-1 , :) , zeros(router.num_rules , 1) , router.num_MF , router.input_bounds);

            fuzzy_R  = fuzzy_engine_11 (A_eval , server.rule_base_R , server.num_MF , server.input_bounds);
            Reward_cost  = cast(R (counter_1) , 'double');
            server.rule_base_R (fuzzy_R.act) = server.rule_base_R (fuzzy_R.act) + Beta_LR * (Reward_cost - fuzzy_R.res) * fuzzy_R.phi;

            counter_2 = 1;

            for h = fuzzy_ind_router.act'
                fuzzy_C = fuzzy_engine_11 (A_eval , server.rule_base_C(:,h) , server.num_MF , server.input_bounds);
                Reward_block  = cast(C (counter_1) , 'double');
                server.rule_base_C(fuzzy_C.act , h) = server.rule_base_C (fuzzy_C.act,h) + Beta_LR * (Reward_block - fuzzy_C.res) * fuzzy_C.phi * fuzzy_ind_router.phi(counter_2);
                counter_2 = counter_2 + 1;
            end

        end

        f_t = zeros(server.num_rules , 1);

        counter_3 = 1;
        for h = fuzzy_ind_router.act'
            f_t  = f_t  + server.rule_base_C(: , h) * fuzzy_ind_router.phi(counter_3);
            counter_3 = counter_3 + 1;
        end

        FFS = max(0 ,  f_t - v);
        F_S(: , 1 : end-1) = F_S(: , 2 : end);
        F_S (: , end) = FFS;
        
        if It >= 3
            W = W * 0.995; 
            W( : , 1 : end - 1) = W( : , 2 : end);
            W (: ,end) = 1;
        end

        P1 = exp(- eta * sum(server.rule_base_R + lambda * F_S (: , end : - 1 : end - min (It - 2 , T_M) ) .*W (: , end : - 1 : end - min (It - 2 , T_M) ) , 2));
        P1 = P1 ./ sum(P1);

        %
        [ ~ , so_10 ] = sort( P1 , 'descend');
        numerate = 2;
        N = [];
        for i = 1:numerate
            a = round(FT_3(so_10(i),:));
            n = sub2ind([4 4 4 4 4 4 4 4 4 4 4] , a(11),a(10),a(9),a(8),a(7),a(6),a(5),a(4),a(3),a(2),a(1));
            P2(n) = P1(so_10(i));
            N = [N;n];
        end
        N = so(N);
        P2 = P2./sum(P2);

        [f2 , c2] = cost_function_final(b(It-1 , :) , server, router , Cost_R , Cost_C , N);
        Expected_block   (It - 1) = cast(f2(so),'double')' * P2;
        Expected_reserve (It - 1) = cast(c2(so),'double')' * P2;
        clear f2 c2
        % server.probability(It) = sqrt( sum((probability_aux_normalized_pre - probability_aux_normalized) .^2) );
        %
        % probability_aux_normalized_pre = probability_aux_normalized;
        %%
        r1 = rand;
        r2 = find(r1 < cumsum(P2) , 1 ,'first');
        A(It,:) = FT_4(r2 , :);
        Y = sub2ind(4*ones(1,11) , A(It,1) , A(It,2) , A(It,3), A(It,4) , A(It,5) , A(It,6), A(It,7) , A(It,8) , A(It,9), A(It,10) , A(It,11));
        Repeat_a( : , 1:end-1 ) = Repeat_a( : , 2:end ); Repeat_a( : , end ) = 0;
        Repeat_a( Y , end )     = 1;
        
    end

    %%
    
    clc
    fprintf("The process has been %.3f %% completed! \n",It * 100 / time_horizon)

end
Time = toc;
save(sprintf('Result.mat'))