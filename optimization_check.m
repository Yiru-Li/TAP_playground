msh = mesh_load_gmsh4(fnamehead);
mesh_show_surface(msh, 'showSurface', true)
hold on
l = scatter3(target(1), target(2), target(3), 'filled', 'DisplayName', 'Target Center');
l = [l plot3([target(1) target(1)+5*target_direction(1)], ...
    [target(2) target(2)+5*target_direction(2)], ...
    [target(3) target(3)+5*target_direction(3)], ...
    'LineWidth', 2, 'DisplayName', 'E-field Direction')];
hold off
legend(l)