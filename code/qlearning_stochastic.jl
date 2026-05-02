module qlearning_stochastic

    export simulate_game

    using Random, QuantEcon

    const MASTER_SEED = 111 

        function get_actions(game::Main.init_stochastic.model, Q::Array{Float32,5}, a::Vector{Int8}, cost::Vector{Int64},t::Int64, i::Int64, j::Int64,s::Int64, rng::AbstractRNG)::Vector{Int8}
            # Action module
            a_current = Int8.(zeros(game.n));
            a_current[j]=a[j];
            pr_explore::Float64 = exp(- t * game.beta);
            e = pr_explore > rand(rng)
            a_current[i] = e ? Int8(rand(rng, 1:game.dim_A)) : Int8(argmax(Q[i, a_current[j], cost[t], cost[t-1], :]))
            return a_current
        end

        
        function update_Q(game::Main.init_stochastic.model, Q::Array{Float32,5}, t::Int64, i::Int64, j::Int64, d::Int64, profit_matrix::Matrix{Float32}, cost::Vector{Int64}, a::Array{Int8,2}, stable::Array{Int64,1})::Tuple{Array{Float32,5},Array{Int64,1}}
            # The state of firm i at period t is given by: s_it = (p_jt-1, c_t-1, c_t)
            
            # Learning module
            old_value = Q[i, a[t-2,j], cost[t-2], cost[t-3], a[t-2,i]]
            old_argmax = argmax(Q[i, a[t-2,j], cost[t-2], cost[t-3],:])
        
            max_q = maximum(Q[i, a[t-1,j], cost[t-1], cost[t-2],:])  # Use maximum to find the max Q-value
            new_value = profit_matrix[t-2,i] + game.delta[d] * profit_matrix[t-1,i] + game.delta[d]^2 * max_q
            Q[i, a[t-2,j], cost[t-2], cost[t-3], a[t-2,i]] = (1 - game.alpha) * old_value + game.alpha * new_value
        
            # Check stability
            new_argmax = argmax(Q[i, a[t-2,j], cost[t-2], cost[t-3], :])
            same_argmax = Int8(old_argmax == new_argmax)
            stable[i] = (stable[i] + same_argmax) * same_argmax  
            
            return Q, stable
        end


        function check_convergence(game::Main.init_stochastic.model, t::Int64, i::Int64, stable::Array{Int64,1})::Bool
            # Check for convergence
            if minimum(stable) > game.tstable && isodd(t)  
                #print("\nConverged!")
                return true;
            elseif t==game.tmax
                #print("\nERROR! Not Converged!")
                return true;
            else
                return false;
            end
        end

        
        function export_game(game::Main.init_stochastic.model)
            #Export game
            open("output/games/game1.json", "w") do io
                JSON3.write(io, game)
            end 
        end



    function simulate_game(game::Main.init_stochastic.model)::Tuple{Array{Float32,8}, Array{Float32,5}, Array{Int8,5}, Array{Int8,4},Array{Int64,3}, Array{Int64,7}}
            Q_all::Array{Float32,8} = zeros(game.n, game.dim_A, game.dim_C, game.dim_C, game.dim_A, game.S, game.dim_rho, game.dim_delta);
            PI = Array{Float32,5}(undef, game.tstable, game.n , game.S, game.dim_rho, game.dim_delta);
            a_converge = Array{Int8,5}(undef, game.tstable, game.n,game.S, game.dim_rho, game.dim_delta);
            cost_matrix = Array{Int8,4}(undef, game.tstable,game.S, game.dim_rho, game.dim_delta);
            t_final_mat::Array{Int64,3}=zeros(game.S, game.dim_rho, game.dim_delta);
            bf::Array{Int64,7}=zeros(Int64, game.n, game.dim_A, game.dim_C, game.dim_C, game.S, game.dim_rho, game.dim_delta);
            
            

            for d=1:game.dim_delta    
                for r=1:game.dim_rho
                    for s=1:game.S
                        seed = MASTER_SEED + 10_000*d + 100*r + s
                        rng  = MersenneTwister(seed)
                        a = Matrix{Int8}(undef, game.tmax, game.n)  # Store actions
                        cost = Vector{Int64}(undef, game.tmax)  # Store cost
                        Q::Array{Float32,5} = zeros(game.n, game.dim_A, game.dim_C, game.dim_C, game.dim_A);
                        
                        if game.dim_C==2
                            P = [game.rho[r] 1-game.rho[r] ; 1-game.rho[r] game.rho[r]];
                        elseif game.dim_C==3
                            P = [game.rho[r] (1-game.rho[r])/2 (1-game.rho[r])/2 ; (1-game.rho[r])/2 game.rho[r] (1-game.rho[r])/2 ; (1-game.rho[r])/2 (1-game.rho[r])/2 game.rho[r]];
                        end
                        P = Float64.(P) 
                        P ./= sum(P, dims=2)  
                        mc = MarkovChain(P)
                        Random.seed!(rng) 
                        cost = simulate(mc, game.tmax)
                        Random.seed!() 

                        t0=4; # periods for initial state
                        a[1:t0,:] = Int8.(rand(rng, 1:game.dim_A, 4, game.n)) # Initial state

                        profit_t_2 = game.PI[:, a[3,1], a[4,2],cost[3]] # profits at period t-2
                        profit_t_1 = game.PI[:, a[4,1], a[4,2],cost[4]] # profits at period t-1
                        profit_matrix = Matrix{Float32}(undef, game.tmax, 2) 
                        profit_matrix[1:2,1:2] = vcat(profit_t_2', profit_t_1')
                        
                        stable = Int64.(zeros(game.n));
                        t_final::Int32 = 1 
                    
                        i=1; j=2;
                        for t=5:game.tmax
                            Q, stable = update_Q(game, Q, t, i, j, d, profit_matrix, cost, a, stable)
                            
                            a_current = get_actions(game, Q, a[t-1, :], cost, t, i, j, s,rng) 
                            a[t, :] = a_current
                            
                            profit_t = game.PI[:, a_current[i], a_current[j], cost[t]]
                            profit_matrix[t, i] = profit_t[1]
                            profit_matrix[t, j] = profit_t[2]


                            if check_convergence(game, t, i, stable)
                                println("\nSimulation $s ends at t = $t")
                                break
                            end
                            
                            i, j = j, i # Swap i and j for the next iteration
                            t_final = t
                        end

                        Q_all[:,:,:,:,:,s,r,d]=Q;
                        PI[:,:,s,r,d]=profit_matrix[t_final-game.tstable+1:t_final,:];
                        a_converge[:,:,s,r,d]=a[t_final-game.tstable+1:t_final,:];
                        cost_matrix[:,s,r,d] = cost[t_final-game.tstable+1:t_final];
                        t_final_mat[s,r,d]=t_final;
                    end 
                end
            end

            # best response strategy
            for d=1:game.dim_delta
                for r=1:game.dim_rho
                    for s=1:game.S
                        for n=1:game.n
                            for c=1:game.dim_C
                                for c1=1:game.dim_C
                                    for a=1:game.dim_A
                                        bf[n,a,c,c1,s,r,d]= argmax(Q_all[n,a,c,c1,:,s,r,d]);
                                    end
                                end
                            end
                        end
                    end
                end
            end
        
        return Q_all, PI, a_converge, cost_matrix, t_final_mat, bf
    end

end


