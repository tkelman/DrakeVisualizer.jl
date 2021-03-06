using DrakeVisualizer
using GeometryTypes
using CoordinateTransformations
using Meshing
using Base.Test
using IJulia
import Iterators: product

proc = DrakeVisualizer.new_window()

try
    @testset "robot_load" begin
        f = x -> norm(x)^2
        bounds = HyperRectangle(Vec(0.,0,0), Vec(1.,1,1))
        geom = contour_mesh(f, minimum(bounds), maximum(bounds))
        robot = convert(Robot, geom)
        vis = Visualizer(robot, 1)
    end

    @testset "link_list_load" begin
        links = Link[]
        levels = [0.5; 1]
        for i = 1:2
            f = x -> norm(x)^2
            geom = contour_mesh(f, Vec(0.,0,0), Vec(1.,1,1), levels[i])
            push!(links, Link(geom))
        end
        vis = Visualizer(links, 1)
    end

    @testset "geom_load" begin
        f = x -> norm(x)^2
        iso_level = 0.5
        geom = GeometryData(contour_mesh(f, [0.,0,0], [1.,1,1], iso_level))
        vis = Visualizer(geom)
    end


    @testset "robot_draw" begin
        links = Link[]
        link_lengths = [1.; 2; 3]
        for (i, l) in enumerate(link_lengths)
            geometry = HyperRectangle(Vec(0., -0.1, -0.1), Vec(l, 0.2, 0.2))
            geometry_data = GeometryData(geometry)
            push!(links, Link([geometry_data], "link$(i)"))
        end


        function link_origins(joint_angles)
            transforms = Array{Transformation}(length(link_lengths))
            transforms[1] = LinearMap(AngleAxis(joint_angles[1], 0, 0, 1.0))
            for i = 2:length(link_lengths)
                T = compose(Translation(link_lengths[i-1], 0, 0),
                            LinearMap(AngleAxis(joint_angles[i], 0, 0, 1.0))
                            )
                transforms[i] = compose(transforms[i-1], T)
            end
            transforms
        end

        robot = Robot(links)
        model = Visualizer(robot)

        for x in product([linspace(-pi, pi, 11) for i in 1:length(link_lengths)]...)
            origins = link_origins(reverse(x))
            draw(model, origins)
        end
    end

    @testset "ellipsoid" begin
        ellipsoid = DrakeVisualizer.HyperEllipsoid(Point(1.,0,0.1), Vec(0.3, 0.2, 0.1))
        Visualizer(ellipsoid)
    end

    @testset "cylinder" begin
        cylinder = DrakeVisualizer.HyperCylinder{3, Float64}(1.0, 0.5)
        Visualizer(cylinder)
    end

    @testset "multiple_robots" begin
        robot1 = convert(Robot, DrakeVisualizer.HyperCylinder{3, Float64}(1.0, 0.5))
        robot2 = convert(Robot, DrakeVisualizer.HyperRectangle(Vec(0., -0.1, -0.1), Vec(1, 0.2, 0.2)))
        vis1, vis2 = Visualizer([robot1, robot2])
        for vis in [vis1, vis2]
            draw(vis, [IdentityTransformation()])
        end
    end

    @testset "demo_notebook" begin
        if VERSION < v"0.6-dev"
            jupyter = IJulia.jupyter
            demo_file = "../demo.ipynb"
            run(`$jupyter nbconvert --to notebook --execute $(demo_file) --output $(demo_file)`)
        end
    end
finally
    kill(proc)
end
