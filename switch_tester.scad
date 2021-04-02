// OpenSCAD settings
subtract_overlap = 1;
$fn = 50;

// Printer settings
extrusion_width = 0.4;
fit_compensation = 0.15;

// Switch dimensions
switch_depth = 13.7; // north-south
switch_width = switch_depth; // east-west (some switches are narrower here)
// total height of the lower half of the switch from the top of the plate to the lowest point of the
// lowest point of the switch
switch_height = 8.3;
unit = 19;

// Click ledge dimensions
ledge_width = 5;
ledge_depth = 0.8;
// this is the hight of the plate for plates that are a simple cutout
ledge_height = 1.35;

// Edge overshoot dimensions
edge_overshoot_depth = 0.4;
edge_overshoot_width = 1;

// Module dimensions
module_height = switch_height;
rack_wall_thickness = 3*extrusion_width;
module_hole_width = unit-rack_wall_thickness;
module_width = module_hole_width-fit_compensation;

// label recess dimensions
label_recess_depth = 0.25;
label_recess_border = 1;

// switch_plate dimensions
plate_rows = 1;
plate_columns = 1;
plate_bottom_thickness = 1.5;
plate_border_thickness = 4;
plate_chamfer = 2;

// holding notch dimensions
notch_radius = 1.5;
notch_angle = 30;
notch_width = 5;
notch_height = 0.5;
notch_groove_width = notch_width + 1;
notch_groove_height_difference = 0.1;

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

module chamfered_cylinder(r, h, r_cham, max_overlap=60) {
    intersection() {
        hull() {
            translate([0,0,h-r_cham]) donut(r, r_cham);
            translate([0,0,sin(max_overlap)*r_cham]) donut(r, r_cham);
        };
        cylinder(h=h+subtract_overlap, r=r+subtract_overlap);
    }
}

module switch_cutout() {
    translate([0, 0, -1*subtract_overlap]){
        linear_extrude(module_height+2*subtract_overlap) {
            square([switch_width, switch_depth], center=true);
            copy_mirror()
            translate([0, switch_depth/2-edge_overshoot_width/2, 0])
            square([switch_width+2*edge_overshoot_depth, edge_overshoot_width], center=true);
        };
        linear_extrude(module_height+subtract_overlap-ledge_height)
        square([ledge_width,switch_depth+2*ledge_depth], center=true);
    }
}

module label_recess() {
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

module notch(width) {
    copy_mirror([1,0,0])
    translate([
        module_hole_width/2+cos(notch_angle)*notch_radius,
        0,
        sin(notch_angle)*notch_radius+notch_height
    ])
    rotate([90,0,0])
    cylinder(h=width, r=notch_radius, center=true);
}

module switch_module() {
    difference() {
        linear_extrude(module_height)
        square(module_width, center=true);
        switch_cutout();
        label_recess();
        notch(notch_groove_width);
    }
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
                plate_bottom_thickness-notch_groove_height_difference
            ])
            notch(notch_width);
        }
    }
}

module switch_plate() {
    difference() {
        minkowski() {
            cube([unit*plate_columns, unit*plate_rows,1]);
            chamfered_cylinder(
                r = plate_border_thickness,
                h = plate_bottom_thickness+module_height-1,
                r_cham = plate_chamfer
            );
        };
        for(i = [0:plate_columns-1], j = [0:plate_rows-1])
        translate([i*unit, j*unit, 0])
        plate_hole();
    }
}

switch_plate();
//switch_module();
