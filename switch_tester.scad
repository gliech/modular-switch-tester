// OpenSCAD settings
subtract_overlap = 1;
$fn = 100;

// Printer settings
extrusion_width = 0.4;
fit_compensation = 0.1;

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
ledge_height = 1.4;

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
plate_columns = 4;
plate_bottom_thickness = 1.5;
plate_border_thickness = 3;

module copy_mirror(vec=[0,1,0])
{
    children();
    mirror(vec) children();
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

module switch_module() {
    difference() {
        linear_extrude(module_height)
        square(module_width, center=true);
        #switch_cutout();
        #label_recess();
    }
}

module plate_hole() {
    translate([rack_wall_thickness/2, rack_wall_thickness/2, 0]) {
        translate([0, 0, plate_bottom_thickness])
        cube([module_hole_width, module_hole_width, module_height+subtract_overlap]);
        translate([0, (module_hole_width-switch_depth)/2, -1*subtract_overlap])
        cube([module_hole_width, switch_depth, plate_bottom_thickness+2*subtract_overlap]);
    }
}

module switch_plate() {
    difference() {
        linear_extrude(plate_bottom_thickness+module_height)
        minkowski() {
            square([unit*plate_columns, unit*plate_rows]);
            circle(plate_border_thickness);
        };
        for(i = [0:plate_columns-1], j = [0:plate_rows-1])
        translate([i*unit, j*unit, 0])
        plate_hole();
    }
}


switch_plate();
translate([-30,0,0])switch_module();
