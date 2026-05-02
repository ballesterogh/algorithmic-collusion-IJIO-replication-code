# Q-learning Functions

module qlearning_deterministic

    export simulate_game

    using Random

    const MASTER_SEED = 111 

        function get_actions(game::Main.init_deterministic.model, Q::Array{Float32,3}, a::Vector{Int8}, t::Int64, i::Int64, j::Int64,s::Int64,rng::AbstractRNG)::Vector{Int8}
            # Action module
            a_current = Int8.(zeros(game.n));
            a_current[j]=a[j];
            pr_explore::Float64 = exp(- t * game.beta);
            Random.seed!((s-1)*100+t)
            e = pr_explore > rand(rng)
            a_current[i] = e ? Int8(rand(rng, 1:game.dim_A)) : Int8(argmax(Q[i, a_current[j], :]));
            return a_current
        end

        
        function update_Q(game::Main.init_deterministic.model, Q::Array{Float32,3}, t::Int64, i::Int64, j::Int64, profit_matrix::Matrix{Float32}, a::Array{Int8,2}, stable::Array{Int64,1})::Tuple{Array{Float32,3},Array{Int64,1}}
            # Learning module
            old_value = Q[i, a[t-2,j], a[t-2,i]]
            old_argmax = argmax(Q[i, a[t-2,j], :])
        
            max_q = maximum(Q[i, a[t-1,j], :])  # Use maximum to find the max Q-value
            new_value = profit_matrix[t-2,i] + game.delta * profit_matrix[t-1,i] + game.delta^2 * max_q
            Q[i, a[t-2,j], a[t-2,i]] = (1 - game.alpha) * old_value + game.alpha * new_value
        
            # Check stability
            new_argmax = argmax(Q[i, a[t-2,j], :])
            same_argmax = Int8(old_argmax == new_argmax)
            stable[i] = (stable[i] + same_argmax) * same_argmax  
            
            return Q, stable
        end


        function check_convergence(game::Main.init_deterministic.model, t::Int64, i::Int64, stable::Array{Int64,1})::Bool
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

        
        function export_game(game::Main.init_deterministic.model)
            #Export game
            open("output/games/game1.json", "w") do io
                JSON3.write(io, game)
            end 
        end


    function simulate_game(game::Main.init_deterministic.model)::Tuple{Array{Float32,4}, Array{Float32,3}, Array{Int8,3},Array{Int64,1},Array{Int64,3}}
        Q_all::Array{Float32,4} = zeros(game.n, game.dim_A, game.dim_A,game.S);
        PI = Array{Float32,3}(undef, game.tstable, 2,game.S) 
        a_converge = Array{Int8,3}(undef, game.tstable, 2,game.S) 
        t_final_mat::Array{Int64,1}=zeros(game.S) 
        bf::Array{Int64,3}=zeros(Int64, game.n, game.dim_A, game.S);

        for s=1:game.S
            seed = MASTER_SEED + s
            rng  = MersenneTwister(seed)
            a = Matrix{Int8}(undef, game.tmax, 2)  # Store actions
            Q::Array{Float32,3} = zeros(game.n, game.dim_A, game.dim_A);
            
            a[1:2,:] = Int8.(rand(rng,1:game.dim_A, 2, 2)) # Initial state
            a[2,1] = a[1,1] # price of firm 1 remains constant at period t=2 
            
            profit_t_2 = game.PI[:, a[1,1], a[1,2]] # profits at period t-2
            profit_t_1 = game.PI[:, a[2,1], a[2,2]] # profits at period t-1
            profit_matrix = Matrix{Float32}(undef, game.tmax, 2) 
            profit_matrix[1:2,1:2] = vcat(profit_t_2', profit_t_1')
            
            stable = Int64.(zeros(game.n));
            t_final::Int32 = 1 
        
            i=1; j=2;
            for t=3:game.tmax
                Q, stable = update_Q(game, Q, t, i, j, profit_matrix, a, stable)
                
                a_current = get_actions(game, Q, a[t-1, :], t, i, j,s, rng) 
                a[t, :] = a_current
                
                profit_t = game.PI[:, a_current[i], a_current[j]]
                profit_matrix[t, i] = profit_t[1]
                profit_matrix[t, j] = profit_t[2]


                if check_convergence(game, t, i, stable)
                    println("\nSimulation $s ends at t = $t")
                    break
                end
                
                # Swap i and j for the next iteration
                i, j = j, i
                t_final = t
            end
             

            PI[:,:,s]=profit_matrix[t_final-game.tstable+1:t_final,:]
            a_converge[:,:,s]=a[t_final-game.tstable+1:t_final,:]
            Q_all[:,:,:,s]=Q;
            t_final_mat[s]=t_final
        end 

          # best response strategy
            for s=1:game.S
                for n=1:game.n
                    for a=1:game.dim_A
                        bf[n,a,s]= argmax(Q_all[n,a,:,s]);
                    end
                end
            end
            

        return Q_all, PI, a_converge, t_final_mat, bf
    end

end


