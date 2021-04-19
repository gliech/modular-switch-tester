/* [general] */
// generate only the plate, only the module or both
output = "develop"; // ["develop", "module", "plate"]
// use higher setting for fn when models are exportet as stl
$fn = output == "develop" ? 20 : 200;

/* [switch module - general] */
// width of the switch at the height where it sits on the plate
switch_width = 13.9;
switch_depth = switch_width;
// height difference between the top of the plate and the bottom of the contact pin
switch_height = 8.4;
// clearance between module and the slot in the plate
module_clearance_gap = 0.15;
// distance between the same points on neighboring switches
unit = 19;
module_floor_thickness = 1;
module_height = switch_height+module_floor_thickness;

/* [switch module - click ledge] */
// this is the same as the thickness of your typical keyboard mounting plate
ledge_thickness = 1.45;
ledge_width = 5;
ledge_depth = 0.8;

/* [switch module - edge overshoot] */
edge_overshoot_depth = 0.4;
edge_overshoot_width = 1;

/* [switch module - label recess] */
label_recess_depth = 0.3;
label_recess_border = 1;

/* [switch plate] */
plate_rows = 1;
plate_columns = 1;
plate_bottom_thickness = 1;
plate_border_thickness = 5;
// this can be at most half the border thickness because of how the chamfer is created (could be fixed if needed)
plate_chamfer_radius = 2.5;
plate_chamfer_max_overhang = 60;
// should be at least twice the extrusion width of your FDM printer
rack_wall_thickness = 1.2;
module_hole_width = unit-rack_wall_thickness;
module_width = module_hole_width-module_clearance_gap;

/* [bumps] */
bump_radius = 1.5;
bump_angle = 19.7;
bump_width = 6;
bump_height = 0.5;
module_bump_positions = [0,1,3];
plate_bump_positions = [1,3];
bump_notch = false;
bump_notch_width = bump_width + 1;
bump_notch_height_difference = 0.1;

/* [Hidden] */
subtract_overlap = 1;

module copy_mirror(vec=[0,1,0])
{
    children();
    mirror(vec) children();
}

module donut(r1, r2) {
    rotate_extrude()
    translate([r1-r2,0,0])
    circle(r2);
}

module chamfered_cylinder(r, h, r_cham, max_overhang=60) {
    intersection() {
        hull() {
            translate([0,0,h-r_cham]) donut(r, r_cham);
            translate([0,0,sin(max_overhang)*r_cham]) donut(r, r_cham);
        };
        cylinder(h=h+subtract_overlap, r=r+subtract_overlap);
    }
}

module switch_cutout() {
    translate([0, 0, (sign(module_floor_thickness)-1)*subtract_overlap+module_floor_thickness]){
        linear_extrude(switch_height+(2-sign(module_floor_thickness))*subtract_overlap) {
            square([switch_width, switch_depth], center=true);
            copy_mirror()
            translate([0, switch_depth/2-edge_overshoot_width/2, 0])
            square([switch_width+2*edge_overshoot_depth, edge_overshoot_width], center=true);
        };
        linear_extrude(switch_height+(1-sign(module_floor_thickness))*subtract_overlap-ledge_thickness)
        square([ledge_width,switch_depth+2*ledge_depth], center=true);
    }
}

module label_recess() {
    rotate([0,0,180])
    translate([
        -1*module_width/2+label_recess_border,
        module_width/2-label_recess_depth,
        label_recess_border
    ])
    cube([
        module_width-2*label_recess_border,
        label_recess_depth+subtract_overlap,
        module_height-2*label_recess_border
    ]);
}

module bump(width, bump_positions, reverse = false) {
    for(i=bump_positions) {
        rotate([0,0,90-90*i])
        translate([
           module_hole_width/2+cos(bump_angle)*bump_radius*(reverse ? -1 : 1),
           0,
           (reverse ? module_height : 0)+(reverse ? -1 : 1)*(sin(bump_angle)*bump_radius+bump_height)
        ])
        rotate([90,0,0])
        difference(){
          cylinder(h=width, r=bump_radius, center=true);
          translate([(1-cos(bump_angle))*bump_radius*(reverse ? -1 : 1)-(reverse ? module_clearance_gap/2 : 0),0,0])
          cube([
              2*bump_radius,
              2*bump_radius+2*subtract_overlap,
              bump_width+2*subtract_overlap
          ], center = true);
        }
    }
}

module switch_module() {
    difference() {
        linear_extrude(module_height)
        square(module_width, center=true);
        switch_cutout();
        label_recess();
        if (bump_notch) bump(bump_notch_width, plate_bump_positions);
    };
    bump(bump_width, module_bump_positions, reverse=true);
}

module plate_hole() {
    translate([rack_wall_thickness/2, rack_wall_thickness/2, 0]) {
        difference() {
            union() {
                translate([0, 0, plate_bottom_thickness])
                cube([module_hole_width, module_hole_width, module_height+subtract_overlap]);
                translate([0, (module_hole_width-switch_depth)/2, -1*subtract_overlap])
                cube([module_hole_width, switch_depth, plate_bottom_thickness+2*subtract_overlap]);
            };
            translate([
                module_hole_width/2,
                module_hole_width/2,
                plate_bottom_thickness-bump_notch_height_difference
            ])
            bump(bump_width, plate_bump_positions);
        }
    }
}

module switch_plate(columns, rows) {
    difference() {
        minkowski() {
            cube([unit*columns, unit*rows,1]);
            chamfered_cylinder(
                r = plate_border_thickness,
                h = plate_bottom_thickness+module_height-1,
                r_cham = plate_chamfer_radius,
                max_overhang = plate_chamfer_max_overhang
            );
        };
        for(i = [0:columns-1], j = [0:rows-1])
        translate([i*unit, j*unit, 0])
        plate_hole();
    }
}

if (output == "develop") {
    translate([5, 5, 0])switch_plate(10,4);
    translate([-12, 12, 0])switch_module();
    // echo((1-cos(bump_angle))*bump_radius*2);
} else if (output == "module") {
    switch_module();
} else {
    switch_plate(plate_columns, plate_rows);
}
