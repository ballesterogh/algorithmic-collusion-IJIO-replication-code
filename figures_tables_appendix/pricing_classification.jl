
function pricing_classification(game, bf)

    # Clasification: focal, alternate, partial and cycle
    focal_single_idx = zeros(Bool, game.S, game.dim_rho, game.dim_delta);
    focal_single_action = zeros(Int64, game.S, game.dim_rho, game.dim_delta);
    focal_single_price = zeros(Float32, game.S, game.dim_rho, game.dim_delta);

    focal_alternate_idx = zeros(Bool, game.S, game.dim_rho, game.dim_delta);
    focal_alternate_action = zeros(Int64, game.S, game.dim_rho, game.dim_delta, game.dim_C);
    focal_alternate_price = zeros(Float32, game.S, game.dim_rho, game.dim_delta, game.dim_C);

    focal_low_idx = zeros(Bool, game.S, game.dim_rho, game.dim_delta);
    focal_high_idx = zeros(Bool, game.S, game.dim_rho, game.dim_delta);
    focal_low_action = zeros(Int64, game.S, game.dim_rho, game.dim_delta);
    focal_high_action = zeros(Int64, game.S, game.dim_rho, game.dim_delta);

    cycle_idx = zeros(Bool, game.S, game.dim_rho, game.dim_delta);

    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for s=1:game.S
                A=repeat(game.A', game.n)
                y_low=sum(bf[:,:,1,1,s,r,d].== A,dims=1);
                y_high=sum(bf[:,:,2,2,s,r,d].== A,dims=1);
                idx0_low = findall(x -> x == 2, y_low)
                idx0_high = findall(x -> x == 2, y_high)
                idx_low = LinearIndices(y_low)[idx0_low]
                idx_high = LinearIndices(y_high)[idx0_high]

                if maximum(y_low)==2 && maximum(y_high)==2 && idx_low != idx_high
                    focal_alternate_idx[s,r,d]=1;
                
                elseif maximum(y_low)==2 && maximum(y_high)==2 && idx_low == idx_high
                    focal_single_idx[s,r,d]=1;

                elseif maximum(y_low)==2 && maximum(y_high)<2
                    focal_low_idx[s,r,d]=1;

                elseif maximum(y_low)<2 && maximum(y_high)==2
                    focal_high_idx[s,r,d]=1;

                else
                    cycle_idx[s,r,d]=1;
                end
            end
        end
    end

    partial_idx = Bool.(focal_low_idx + focal_high_idx);

return focal_single_idx, focal_alternate_idx, partial_idx, cycle_idx, focal_high_idx, focal_low_idx

end