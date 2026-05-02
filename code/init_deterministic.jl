module init_deterministic

    export init_game

    using Pkg

    required_packages = ["Parameters", "Statistics", "Combinatorics", "NLsolve", "StructTypes"]

    for pkg in required_packages
        try
            @eval using $(Symbol(pkg))
        catch
            println("Installing missing package: $pkg")
            Pkg.add(pkg)
            @eval using $(Symbol(pkg))
        end
    end
    
    # Model properties
    @with_kw mutable struct model
        # Default Properties
        c::Float32                              # Marginal cost
        k::Int8                                 # Dimension of the price grid
        delta::Float32 = 0.95                   # Discount factor
        n::Int8 = 2                             # Number of firms
        alpha::Float32 = 0.15                   # Learning parameter
        beta::Float32 = 4e-6                    # Learning parameter
        S::Int32 = 1000
        tstable::Int32 = 1e5                    # Number of iterations needed for stability
        tmax::Int32 = 1e7                       # Maximum number of iterations
        
        # Derived Properties
        A::Array{Int8,1} = zeros(1)             # Action space
        P::Array{Float32,1} = zeros(1)          # Price space
        dim_A::Int64 = 0
        p_nash::Float32 = 0
        p_monopoly::Float32 = 0
        profit_nash::Float32 = 0
        profit_monopoly::Float32 = 0
        demand::Array{Float32, 3} = zeros(1,1,1)
        PI::Array{Float32, 3} = zeros(1,1,1)
    end

    # Save struct type
    StructTypes.StructType(::Type{model}) = StructTypes.Mutable()
    
    function compute_p_competitive_monopoly(game::model)::Tuple{Float32, Float32, Float32, Float32}
        # Computes competitive and monopoly prices
        p_nash = Float32(game.c) + 1/game.k
        p_monopoly = Float32((1 + game.c) / 2)  
        profit_monopoly=(1-p_monopoly)*(p_monopoly-game.c)
        profit_nash=(1-p_nash)*(p_nash-game.c)
        return p_nash, p_monopoly, profit_nash, profit_monopoly
    end

    function init_actions(game::model)::Tuple{Vector{Float32}, Vector{Int8},Int64}
        # Get action space of the firms
        P = collect(0:1/game.k:1)
        A = collect(1:1:length(P))
        dim_A = length(A);
        return P, A, dim_A
    end

    
    function demand_compute(game::model)::Array{Float32, 3}
        dim_A = length(game.A)
        demand = zeros(Float32, game.n, dim_A, dim_A)
        for i in 1:dim_A
            for j in 1:dim_A
                p_i = game.P[game.A[i]]  
                p_j = game.P[game.A[j]]  
    
                if p_i < p_j
                    demand[1, i, j] = 1 - p_i  
                    demand[2, i, j] = 0        
    
                elseif p_j < p_i
                    demand[1, i, j] = 0        
                    demand[2, i, j] = 1 - p_j  
    
                else
                    demand[1, i, j] = (1 - p_i) / 2  
                    demand[2, i, j] = (1 - p_j) / 2  
                end
            end
        end
        
        return demand
    end

   
    function init_PI(game::model)::Array{Float32,3}
        # Initialize Profits (k^n x n)
        dim_A = length(game.A)
        PI = zeros(game.n, dim_A, dim_A);

        for i=1:dim_A
            for j=1:dim_A
                d = demand_compute(game);
                p_i = game.P[i]  
                p_j = game.P[j]  
                
                profit_i = (p_i-game.c)*d[1, i, j]
                profit_j = (p_j-game.c)*d[2, i, j] 

                PI[:,i, j] = [profit_i, profit_j];
            end
        end
        return PI
    end

    
    # Initializes the game
    function init_game(c,k)::model
        game = model(c=c,k=k)
        game.p_nash, game.p_monopoly, game.profit_nash, game.profit_monopoly = compute_p_competitive_monopoly(game)
        game.P, game.A,game.dim_A = init_actions(game)
        game.demand = demand_compute(game)
        game.PI = init_PI(game)
        return game
    end
end
