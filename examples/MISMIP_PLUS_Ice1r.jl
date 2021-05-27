using WAVI 
function MISMIP_PLUS_Ice1r()
    #Grid and boundary conditions
    nx = 80
    ny = 10
    nσ = 4
    x0 = 0.0
    y0 = -40000.0
    dx = 8000.0
    dy = 8000.0
    h_mask=trues(nx,ny)
    u_iszero = falses(nx+1,ny); u_iszero[1,:].=true
    v_iszero=falses(nx,ny+1); v_iszero[:,1].=true; v_iszero[:,end].=true
    grid = Grid(nx = nx, 
                ny = ny,   
                nσ = nσ, 
                x0 = x0, 
                y0 = y0, 
                dx = dx, 
                dy = dy,
                h_mask = h_mask, 
                u_iszero = u_iszero, 
                v_iszero = v_iszero)

    #Bed 
    bed = WAVI.mismip_plus_bed #function definition

    #solver parameters
    maxiter_picard = 5
    solver_params = SolverParams(maxiter_picard = maxiter_picard)

    #Physical parameters
    default_thickness = 100.0 #set the initial condition this way
    accumulation_rate = 0.3
    params = Params(default_thickness = default_thickness, 
                    accumulation_rate = accumulation_rate)

    #make the model
    model = Model(grid = grid,
                     bed_elevation = bed, 
                     params = params, 
                     solver_params = solver_params)

    #embed the model with some extra physics
    m1(draft,cavity_thickness) = 0.2*tanh(cavity_thickness/75).*max((-100-draft), 0)
    draft = -(ρi / ρw) * model.fields.gh.h
    cavity_thickness = (draft .- model.fields.gh.bed_elevation)
    melt_rate = m1(draft, cavity_thickness)
    melt_rate_model = AnalyticMeltRate(melt_partial_cell = true, melt_rate = melt_rate)
    add_melt_rate_model!(model,melt_rate_model)


    #timestepping parameters
    niter0 = 0
    dt = 0.1
    end_time = 200.
    chkpt_freq = 1000.
    pchkpt_freq = 2000.
    timestepping_params = TimesteppingParams(niter0 = niter0, 
                                            dt = dt, 
                                            end_time = end_time, 
                                            chkpt_freq = chkpt_freq, 
                                            pchkpt_freq = pchkpt_freq)

    #output parameters
    folder = "outputs"
    isdir(folder) && rm(folder, force = true, recursive = true)
    mkdir(folder) #make a clean folder for outputs
    outputs = (h   = model.fields.gh.h,
                u  = model.fields.gh.u,
                v  = model.fields.gh.v) #output velocities and thickness
    output_freq = 1000.
    output_params = OutputParams(outputs = outputs, 
                            output_freq = output_freq,
                            output_format = "mat",
                            output_path = folder,
                            zip_format = "nc")
    
    simulation = Simulation(model = model, 
                        timestepping_params = timestepping_params, 
                        output_params = output_params)
            
    #perform the simulation
    run_simulation!(simulation)
    return simulation
end

@time simulation = MISMIP_PLUS_Ice1r();