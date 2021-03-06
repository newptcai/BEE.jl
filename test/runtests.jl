using BEE
using Suppressor
using Test

function capture_render(c)
    @capture_out render(c)
end

function capture_render()
    @capture_out render()
end

@testset "BEE.jl" begin
    @testset "simple" begin
        BEE.reset()

        example="""new_int(w, 0, 10)
        new_int(x, 0, 5)
        new_int(z, -5, 10)
        new_int(y, -4, 9)
        new_bool(x1)
        new_bool(x4)
        new_bool(x2)
        new_bool(x3)
        int_plus(x, y, z)
        bool_eq(x1, -x2)
        bool_eq(x2, true)
        bool_array_sum_eq([-x1, x2, -x3, x4], w)
        solve satisfy
        """
        ret = @capture_out include("../example/simple-example.jl")
        @test ret == example

        @test "new_int(w, 0, 10)\n" == capture_render(w)

        c = x+y == z
        @test "int_plus(x, y, z)\n" == capture_render(c)

        c = xl[1] == -xl[2]
        @test "bool_eq(x1, -x2)\n" == capture_render(c)

        BEE.reset()
        @constrain xl[1] == -xl[2]
        @test "bool_eq(x1, -x2)\nsolve satisfy\n" == capture_render()

        BEE.reset()
        constrain(xl[1] == -xl[2])
        @test "bool_eq(x1, -x2)\nsolve satisfy\n" == capture_render()

    end

    @testset "Declaring Variable" begin
        BEE.reset()

        @beebool x1
        @test "new_bool(x1)\n" == capture_render(x1)

        x2 = beebool("x2")
        @test "new_bool(x2)\n" == capture_render(x2)

        x3 = beebool(:x3)
        @test "new_bool(x3)\n" == capture_render(x3)

        yl = @beebool y1 y2 y3
        for i in 1:3
            @test "new_bool(y$i)\n" == capture_render(yl[i])
        end

        zl = @beebool z[1:10]
        for i in 1:10
            @test "new_bool(z$i)\n" == capture_render(zl[i])
        end

        (a, b, cl, d) = @beebool a b c[1:10] d
        for i in 1:10
            @test "new_bool(c$i)\n" == capture_render(cl[i])
        end

        BEE.reset()

        @beeint xx 3 55

        @test "new_int(xx, 3, 55)\n" == capture_render(xx)

        il = @beeint i[1:10] 3 7
        for i in 1:10
            @test "new_int(i$i, 3, 7)\n" == capture_render(il[i])
        end
    end

    @testset "Boolean statements" begin
        BEE.reset()

        @beebool x1
        @beebool x2
        x3 = BeeBool("x3")

        c = x1 == x2
        @test "bool_eq(x1, x2)\n" == capture_render(c)

        c = -x1 == x2
        @test "bool_eq(-x1, x2)\n" == capture_render(c)

        c = true == and([x1, -x2, x3])
        @test "bool_array_and([x1, -x2, x3])\n" == capture_render(c)

        c = and([x1, x2]) == -x3
        @test "bool_array_and_reif([x1, x2], -x3)\n" == capture_render(c)

        c = -x3 == BEE.xor(-x1, x2)
        @test "bool_xor_reif(-x1, x2, -x3)\n" == capture_render(c)
    end

    @testset "Integer statements" begin
        BEE.reset()

        @beeint x1 3 7
        @beeint x2 4 6
        x3 = beeint("x3", 10, 15)

        c = (x1 < x2) == true
        @test "int_lt(x1, x2)\n" == capture_render(c)

        c = true == (x1 < x2)
        @test "int_lt(x1, x2)\n" == capture_render(c)

        c = false == (x1 < x2)
        @test "int_lt_reif(x1, x2, false)\n" == capture_render(c)

        c = (x1 < x2) == false 
        @test "int_lt_reif(x1, x2, false)\n" == capture_render(c)

        c = alldiff([x1, x2, x3]) == true
        @test "int_array_allDiff([x1, x2, x3])\n" == capture_render(c)

        c = true == alldiff([x1, x2, x3])
        @test "int_array_allDiff([x1, x2, x3])\n" == capture_render(c)

        c = alldiff([x1, x2]) == x3
        @test "int_array_allDiff_reif([x1, x2], x3)\n" == capture_render(c)

        c = x3 == alldiff([x1, x2])
        @test "int_array_allDiff_reif([x1, x2], x3)\n" == capture_render(c)

        c = x1 * x2 == x3
        @test "int_times(x1, x2, x3)\n" == capture_render(c)

        c = x3 == x1 * x2
        @test "int_times(x1, x2, x3)\n" == capture_render(c)

        c = x1 + x2 == 33
        @test "int_plus(x1, x2, 33)\n" == capture_render(c)

        c = 33 == x1 + x2
        @test "int_plus(x1, x2, 33)\n" == capture_render(c)

        c = max([x1, x2]) == x3
        @test "int_array_max([x1, x2], x3)\n" == capture_render(c)

        c = x3 == max([x1, x2])
        @test "int_array_max([x1, x2], x3)\n" == capture_render(c)
    end

    @testset "Cardinality" begin
        BEE.reset()

        xl = [beebool("x$i") for i in 1:3]

        il = [beeint("i$i", 3, 5) for i in 1:3]

        c = sum(il) == il[1]
        @test "int_array_sum_eq([i1, i2, i3], i1)\n" == capture_render(c)

        c = sum(xl) >= il[1]
        @test "bool_array_sum_geq([x1, x2, x3], i1)\n" == capture_render(c)

        c = sum(xl) > il[1]
        @test "bool_array_sum_gt([x1, x2, x3], i1)\n" == capture_render(c)
    end

    @testset "Boolean arrays relation" begin
        BEE.reset()

        xl = [beebool("x$i") for i in 1:3]

        il = [beebool("i$i") for i in 1:3]

        @beebool b

        c = (xl == il) == true
        @test "bool_arrays_eq([x1, x2, x3], [i1, i2, i3])\n" == capture_render(c)

        c = (xl != il) == true
        @test "bool_arrays_neq([x1, x2, x3], [i1, i2, i3])\n" == capture_render(c)

        c = (xl <= il) == true
        @test "bool_arrays_lex([x1, x2, x3], [i1, i2, i3])\n" == capture_render(c)

        c = (xl < il) == true
        @test "bool_arrays_lexLt([x1, x2, x3], [i1, i2, i3])\n" == capture_render(c)

        c = (xl <= il) == b
        @test "bool_arrays_lex_reif([x1, x2, x3], [i1, i2, i3], b)\n" == capture_render(c)

        c = (xl < il) == b
        @test "bool_arrays_lexLt_reif([x1, x2, x3], [i1, i2, i3], b)\n" == capture_render(c)
    end
end
