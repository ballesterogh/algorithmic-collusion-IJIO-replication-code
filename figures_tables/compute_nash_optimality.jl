function compute_nash_optimality(game, epsilon, actions, cost, Q_matrix, bf)

    V0_matrix = zeros(Float32, game.n, game.dim_A, game.dim_A, game.dim_C, game.S, game.dim_rho, game.dim_delta);


    for d=1:game.dim_delta
        for r=1:game.dim_rho
                for s=1:game.S
                    for n=1:game.n
                        rival = n == 1 ? 2 : 1
                        dif = 1.0; 
                        t=1;
                        V0 = zeros(Float32, game.dim_A, game.dim_C);
                        V_new = zeros(Float32, game.dim_A, game.dim_C);
                        W = zeros(Float32, game.dim_A, game.dim_C);
                        V = zeros(Float32, game.dim_A, game.dim_A, game.dim_C);
                        while dif>epsilon
                                for c_current=1:game.dim_C
                                        for aj=1:game.dim_A
                                            for ai=1:game.dim_A
                                                pi_current = game.PI[1, ai, aj, c_current]; 
                                                if game.dim_C==2
                                                    if c_current==1
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])*game.PI[1, ai, bf[rival,ai,2,c_current,s,r,d],2];    
                                                        EV = game.rho[r]*V0[bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])*V0[bf[rival,ai,2,c_current,s,r,d],2];    
                                                    else
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,ai,2,c_current,s,r,d],2] + (1-game.rho[r])*game.PI[1, ai, bf[rival,ai,1,c_current,s,r,d],1];    
                                                        EV = game.rho[r]*V0[bf[rival,ai,2,c_current,s,r,d],2] + (1-game.rho[r])*V0[bf[rival,ai,1,c_current,s,r,d],1];    
                                                    end
        
                                                elseif game.dim_C==3
                                                    if c_current==1
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,ai,1,c_current,s,r,d],1] + ((1-game.rho[r])/2)*game.PI[1, ai, bf[rival,ai,2,c_current,s,r,d],2] + ((1-game.rho[r])/2)*game.PI[1, ai, bf[rival,ai,3,c_current,s,r,d],3];    
                                                        EV = game.rho[r]*V0[bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])/2*V0[bf[rival,ai,2,c_current,s,r,d],2] + (1-game.rho[r])/2*V0[bf[rival,ai,3,c_current,s,r,d],3];    
                                                    elseif c_current == 2
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,ai,2,c_current,s,r,d],2] + (1-game.rho[r])/2*game.PI[1, ai, bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])/2*game.PI[1, ai, bf[rival,ai,3,c_current,s,r,d],3];    
                                                        EV = game.rho[r]*V0[bf[rival,ai,2,c_current,s,r,d],2] + (1-game.rho[r])/2*V0[bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])/2*V0[bf[rival,ai,3,c_current,s,r,d],3];    
                                                    else
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,ai,3,c_current,s,r,d],3] + (1-game.rho[r])/2*game.PI[1, ai, bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])/2*game.PI[1, ai, bf[rival,ai,2,c_current,s,r,d],2];    
                                                        EV = game.rho[r]*V0[bf[rival,ai,3,c_current,s,r,d],3] + (1-game.rho[r])/2*V0[bf[rival,ai,1,c_current,s,r,d],1] + (1-game.rho[r])/2*V0[bf[rival,ai,2,c_current,s,r,d],2];    
                                                    end   
                                                end
        
                                                W[ai,c_current] = Float32((game.delta[d] * Epi + (game.delta[d]^2) * EV)[1]);
                                                V[ai, aj, c_current] = pi_current + W[ai,c_current];
                                            end
                                            V_new[aj,c_current]=maximum(V[:, aj, c_current]);
                                            #bf_optimal[aj,c_current,s,r,d]=argmax(V[:, aj, c_current]);
                                        end
                                end
                                dif = maximum(abs.(V_new-V0))
                                V0 .= V_new 
                            t=t+1;
                        end
                        #V0_matrix[n,:,:,s,r,d] = V0; 
                        V0_matrix[n,:,:,:,s,r,d] = V; 
                    end
                end
        end
    end
    
    
    bf_optimal = zeros(Int8, game.n, game.dim_A, game.dim_C, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta    
        for r=1:game.dim_rho
                for s=1:game.S
                    for n=1:game.n
                        for c_current=1:2
                            for aj=1:game.dim_A
                                bf_optimal[n,aj,c_current,s,r,d]=argmax(V0_matrix[n, :, aj, c_current,s,r,d]);
                            end
                        end
                    end
                end
        end
    end    
    
    optimality_matrix = zeros(Int8, game.n, game.S, game.dim_rho, game.dim_delta);
    Q_loss_path = zeros(Float32, game.n, game.S, game.dim_rho, game.dim_delta);
    Gamma = zeros(Float32, game.n, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for s=1:game.S
                for n=1:game.n
                    rival = n == 1 ? 2 : 1
                    if n==1
                        state=[actions[end-1,rival,s,r,d], cost[end-1,s,r,d],cost[end-2,s,r,d]];
                        p_own = actions[end-1,n,s,r,d];
                    else
                        state=[actions[end,rival,s,r,d], cost[end,s,r,d], cost[end-1,s,r,d]];
                        p_own = actions[end,n,s,r,d];
                    end
                    
                    simulated = bf[n,state[1],state[2],state[3],s,r,d];
                    theoretical = bf_optimal[n,state[1],state[2],s,r,d];
                    optimality_matrix[n,s,r,d]= simulated == theoretical ? 1 : 0;
                    Gamma[n,s,r,d] =  Float32.(Q_matrix[n,state[1],state[2],state[3],p_own,s,r,d] / maximum(V0_matrix[n,:,state[1],state[2],s,r,d]))[1];
                    Q_loss_path[n,s,r,d] =  Float32.((maximum(V0_matrix[n,:,state[1],state[2],s,r,d])-Q_matrix[n,state[1],state[2],state[3],p_own,s,r,d][1]) / maximum(V0_matrix[n,:,state[1],state[2],s,r,d]))[1];
                end
            end
        end
    end

    Q_loss_all = zeros(Float32, game.n, game.dim_A, game.dim_C, game.dim_C, game.dim_A, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for n=1:game.n
                for s=1:game.S
                    for aj=1:game.dim_A
                        for c=1:game.dim_C
                            for ai=1:game.dim_A
                                Q_loss_all[n,aj, c, 1, ai,s,r,d] = (V0_matrix[n,ai,aj,c,s,r,d]-Q_matrix[n,aj,c,1,ai,s,r,d])/V0_matrix[n,ai,aj,c,s,r,d];
                                Q_loss_all[n,aj, c, 2, ai,s,r,d] = (V0_matrix[n,ai,aj,c,s,r,d]-Q_matrix[n,aj,c,2,ai,s,r,d])/V0_matrix[n,ai,aj,c,s,r,d];
                            end
                        end
                    end
                end
            end
        end
    end
    

    Γ = mean(Gamma, dims=1);
    Γ = reshape(Γ,game.S,game.dim_rho,game.dim_delta);
    nash =  sum(optimality_matrix,dims=1).==2;
    nash = reshape(nash,game.S,game.dim_rho, game.dim_delta);
    Q_loss = mean(Q_loss_path,dims=1);
    Q_loss = reshape(Q_loss,game.S,game.dim_rho, game.dim_delta);
    
    Q1_loss_all = mean(Q_loss_all,dims=1:5);
    Q1_loss_all = reshape(Q1_loss_all,game.S, game.dim_rho, game.dim_delta);

    return nash, Q_loss, Q1_loss_all, Γ
end

