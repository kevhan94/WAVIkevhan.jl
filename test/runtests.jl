


using Test, TestSetExtensions, SafeTestsets

@testset ExtendedTestSet "WAVI tests" begin
    @safetestset "Iceberg" begin

        using WAVI

        include("Iceberg_test.jl")
        wavi=Iceberg_test(10000)
        #Steady state iceberg thickness a = 0.3 m/yr, A=2.0e-17 Pa^-3 a^-1
        #ice density 918 kg/m3 ocean density 1028.0 kg/m3, Glen law n=3.
        h0=((36.0*0.3/(2.0e-17))*(1.0/(9.81*918.0*(1-918.0/1028.0)))^3)^(1.0/4.0)
        relerr=maximum(abs.(wavi.gh.h[wavi.gh.mask].-h0)/h0)
        @test relerr < 1.0e-4
    end

    @safetestset "MISMIP+" begin

        using WAVI

        include("MISMIP_PLUS_test.jl")
        wavi=MISMIP_PLUS_test(20000)
        glmask=diff(sign.(wavi.gh.haf),dims=1).==-2
        glx1=wavi.gh.xx[1:end-1,:][glmask]
        glx2=wavi.gh.xx[2:end,:][glmask]
        haf1=wavi.gh.haf[1:end-1,:][glmask]
        haf2=wavi.gh.haf[2:end,:][glmask]
        glx=glx1+(glx2-glx1).*(zero(haf1)-haf1)./(haf2-haf1)
        glxtest=glx[[1,div(wavi.gh.ny,2),div(wavi.gh.ny,2)+1,wavi.gh.ny]]
        @test (glxtest[4]-glxtest[1])/(glxtest[4]+glxtest[1]) < 1e-4
        @test (glxtest[2]-glxtest[3])/(glxtest[2]+glxtest[3]) < 1e-4
        @test 480000<glxtest[1]<540000
        @test 480000<glxtest[4]<540000
        @test 430000<glxtest[2]<460000
        @test 430000<glxtest[3]<460000
    end

    @safetestset "Pos Fraction" begin
        using WAVI
        z=[-1.0 -1.0 -1.0;-1.0 1.0 -1.0;-1.0 -1.0 -1.0]
        pfh,pfu,pfv=WAVI.pos_fraction(z)
        @test pfh == [0.0 0.0 0.0;0.0 0.5 0.0;0.0 0.0 0.0]
        @test pfu == [0.0 0.0 0.0;0.0 0.25 0.0;0.0 0.25 0.0;0.0 0.0 0.0]
        @test pfv == [0.0 0.0 0.0 0.0;0.0 0.25 0.25 0.0;0.0 0.0 0.0 0.0]
    end

    @safetestset "Pos Fraction Mask" begin
        using WAVI
        z=[-1.0 -1.0 -1.0;-1.0 1.0 -1.0;-1.0 -1.0 -1.0]
        mask=[false false false; false true false; false false false]
        pfh,pfu,pfv=WAVI.pos_fraction(z,mask=mask)
        @test pfh == [0.0 0.0 0.0;0.0 1.0 0.0;0.0 0.0 0.0]
        @test pfu == [0.0 0.0 0.0;0.0 0.5 0.0;0.0 0.5 0.0;0.0 0.0 0.0]
        @test pfv == [0.0 0.0 0.0 0.0;0.0 0.5 0.5 0.0;0.0 0.0 0.0 0.0]
    end
end
