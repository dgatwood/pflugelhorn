
// https://github.com/rcolyer/threads-scad
use <threads-scad/threads.scad>

// https://github.com/chrisspen/gears
use <gears/gears.scad>

// https://github.com/openscad/scad-utils.git
use <scad-utils/transformations.scad>
use <scad-utils/shapes.scad>

// https://github.com/openscad/list-comprehension-demos
use <list-comprehension-demos/skin.scad>

// https://www.thingiverse.com/thing:6629632
// Comment out the examples!
use <variable_extrude/files/variable_extrude.scad>

// To do list:
//
// Add wall in valve
// Add threads for outside of valve casing
// Make caps for top and bottom (identical, with identical holes)
// Make valve tuning slides
// Make tubes between valves
// Make main tubing
// Make main tuning slide
// Make bell
// Make structural supports

/*
 * Note that unless otherwise noted, all dimensions are in mm except for
 * bore, which is in inches, because that is how musical instrument bore
 * sizes are traditionally measured.
 */
 
function inches_to_mm(inches) = inches * 25.4;
function mm_to_inches(mm) = mm / 25.4;
function MAX(a, b) = ((a < b) ? b : a);
function MIN(a, b) = ((a < b) ? a : b);
 
/**
 * Creates a receiver and lead pipe with the specified taper and length.
 * @param outer_diameter_inches    The outer diameter of the mouthpiece at the
 *                                 large end of its taper.
 * @param taper_in_inches_per_inch The amount that the mouthpiece diameter
 *                                 decreases per inch.
 * @param taper_length_in_inches   The total length of the mouthpiece taper.
 * @param lead_pipe_length_in_mm   The length of the entire lead pipe, including
 *                                 the receiver.
 * @param bore                     The expected tubing bore at the far end of
 *                                 the lead pipe.
 * @param thickness_in_mm          The minimum thickness for the tubing.
 * @param nubs                     True to include nubs on the outside for easier
 *                                 tuning (if the lead pipe is used for tuning).
 */
module receiver(outer_diameter_inches, taper_in_inches_per_inch, taper_length_in_inches,
                lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.2,
                bore = 0.413, thickness_in_mm = 2.4, nubs = true, tuning = true,
                disassembled = false) {
  mouthpiece_outer_diameter = inches_to_mm(outer_diameter_inches);
  mouthpiece_outer_diameter_small =
      inches_to_mm(outer_diameter_inches - (taper_in_inches_per_inch * taper_length_in_inches));
  taper_length = inches_to_mm(taper_length_in_inches);
  mmbore = inches_to_mm(bore);
       
  outer_tube_radius = MAX((mouthpiece_outer_diameter + thickness_in_mm) / 2,
                          ((mmbore + thickness_in_mm) / 2));
  
  difference() {
      union() {
          cylinder(lead_pipe_length_in_mm, outer_tube_radius, outer_tube_radius, $fn = 256);
          if (nubs) {
            translate([0, outer_tube_radius + 6, 4]) sphere(4, $fn = 256);
            translate([0, -outer_tube_radius - 6, 4]) sphere(4, $fn = 256);

            // An M3 thumb screw and thumb nut needs a little over 3mm.
            translate([0, 14, 4]) rotate([90, 0, 0]) cylinder(28, 1.6, 1.6, $fn = 256);
          }
      }
      union() {
          cylinder(taper_length, mouthpiece_outer_diameter / 2, mouthpiece_outer_diameter_small / 2,
                   $fn = 256);
          translate([0, 0, -1]) cylinder(1.1, mouthpiece_outer_diameter / 2,
                                         mouthpiece_outer_diameter / 2, $fn = 256);
          translate([0, 0, taper_length - .1]) cylinder(1.1, mouthpiece_outer_diameter_small / 2,
                                         mouthpiece_outer_diameter_small / 2, $fn = 256);
                                         
          // Receiver gap
          receiver_gap_inches = 0.1;
          receiver_gap = inches_to_mm(receiver_gap_inches);
          translate([0, 0, taper_length]) cylinder(receiver_gap, mmbore / 2, mmbore / 2, $fn=256);
          
          // Lead pipe slope
          lead_pipe_interior_length = lead_pipe_length_in_mm - receiver_gap - taper_length;
          translate([0, 0, taper_length + receiver_gap - .01]) cylinder(lead_pipe_interior_length + 0.02, mouthpiece_outer_diameter_small / 2, mmbore / 2, $fn=256);    
      }
  }
  
  if (tuning) {
    // The lead pipe has to slide into something.
    inner_diameter = (outer_tube_radius + slide_gap_expansion) * 2;
    outer_diameter = inner_diameter + (thickness_in_mm * 2);
    translate([0, disassembled ? 30 : 0, disassembled ? 0 : 10]) {
      color([1, .5, .5]) {
        difference() {
          union() {
            cylinder(lead_pipe_length_in_mm - 10, outer_diameter / 2, outer_diameter / 2,
                     $fn = 256);
            straight_tube(lead_pipe_length_in_mm - 10, 1.0,
                          mm_to_inches(inner_diameter));
            translate([-4, outer_tube_radius - 3, 0]) cube([3, 11, 8]);
            translate([1, outer_tube_radius - 3, 0]) cube([3, 11, 8]);
          }
          // Screw hole.
          translate([-5, outer_tube_radius + 4.5, 4]) {
              rotate([0, 90, 0]) cylinder(10, 2, 2, $fn = 256);
          }
          // Slot for tightening the tube..
          translate([-1, outer_tube_radius - 2, -1]) cube([2, 5, 15]);
          translate([0, 0, -1]) cylinder(lead_pipe_length_in_mm + 2, inner_diameter / 2,
                                         inner_diameter / 2, $fn = 256);
        }
      }
    }
  }
}
 
/* A receiver for a standard large morse taper (cornet-style) flugelhorn mouthpiece. */
module large_morse_receiver(lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.2,
                bore = 0.413, thickness_in_mm = 2.4, nubs = true, tuning = true,
                disassembled = false) {
  receiver(0.4350, 0.05, 1.1, lead_pipe_length_in_mm = lead_pipe_length_in_mm,
           slide_gap_expansion = slide_gap_expansion, bore = bore,
           thickness_in_mm = thickness_in_mm, nubs = nubs, tuning = tuning,
           disassembled = disassembled);
}

module small_morse_receiver(lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.2,
                bore = 0.413, thickness_in_mm = 2.4, nubs = true, tuning = true,
                disassembled = false) {

  // Calculated at .415.  Why so small?
  receiver(0.395, 0.05, 1.1, lead_pipe_length_in_mm = lead_pipe_length_in_mm,
           slide_gap_expansion = slide_gap_expansion, bore = bore,
           thickness_in_mm = thickness_in_mm, nubs = nubs, tuning = tuning,
           disassembled = disassembled);
}


/**
 * The rough shape of the valve, without any bores, for the purposes of
 * constructing the outside of the valve and clipping certain elements to
 * the area that falls within the body of the valve.
 *
 * @param valve_gap_expansion The amount to shrink the valve to compensate
 *                            for inaccuracy in the size of the model.
 */
module piston_valve_raw(valve_gap_expansion = 0.1) {
  difference() {
    cylinder(70, 11 - valve_gap_expansion, 11 - valve_gap_expansion, $fn=256);
    // Flat edge
    rotate([0, 0, 45]) translate([-9, 9 - valve_gap_expansion, -1]) cube([20, 20, 72]);
  }
}
 
/**
 * @module valve               A trumpet/cornet/flugelhorn piston valve.
 * @param bore                 The diameter of the tubing in inches.
 * @param odd                  Odd-numbered valves and even-numbered valves
 *                             alternate between the inlet and outlet being
 *                             at the top and bottom and vice-versa.
 * @param valve_gap_expansion  Adjust this based on your 3D printer so
 *                             that the valve moves freely
 *                             without leaking.
 */
module piston_valve(bore=0.413, odd=true, valve_gap_expansion = 0.1) {
  mmbore = inches_to_mm(bore);
  difference() {
    piston_valve_raw(valve_gap_expansion);
    translate([0, 0, 62.5]) cylinder(8, 1.65, 1.65, $fn = 256);  // 3.3mm bore hole to tap an m4 screw for the valve stem.
    
    // To/from valve slide - top (L-bores)
    translate([10, 0, odd ? 46 : 30]) rotate_extrude(angle=360) translate([8, 0, 0]) circle(mmbore / 2);
    translate([0, -11, odd ? 30 : 46]) rotate_extrude(angle=360) translate([8, 0, 0]) circle(mmbore / 2);

    // Slant bore (in to out)
    rotate([0, 0, odd ? 0 : 180]) {
        translate([0, 0, odd ? -16.5 : -28.5]) {
            translate([-8, -8, odd ? 38 : 50]) rotate([-90, 35, 45]) rotate_extrude(angle=90) translate([8, 0, 0]) circle(mmbore / 2);
            rotate([0, 0, 180]) translate([-8, -8, odd ? 38 : 50]) rotate([90, -35, 45]) rotate_extrude(angle=90) translate([8, 0, 0]) circle(mmbore / 2);
            translate([-4, -4.5, odd ? 31.5 : 43.5]) rotate([-32, 32, -3])
                cylinder(18, mmbore/2, mmbore/2, $fn = 256);
        };
    }
        
    // Indent in bottom for valve oil
    translate([0, 0, -1]) cylinder(6, 9, 9, $fn = 256);
    
    // Vented valve
    rotate([25, 25, 0]) cylinder(20, 2, 2, $fn = 256);
  }
  // Wall between slant bore and L-bore
  intersection() {
  // even
    if (odd) {
      translate([0, -15, 14]) rotate([20, -35, 45]) cube([30, 30, 2]);
    } else {
      translate([0, -25, 28]) rotate([27, 35, 45]) cube([30, 30, 2]);
    }
    piston_valve_raw(valve_gap_expansion);
  }
}

module piston_valve_casing(bore=0.413, odd=true, valve_thread_pitch = 2) {
    casing_height = 101.5;

    mmbore = inches_to_mm(bore);
    AugerHole(24, 22, 5, valve_thread_pitch, position = [0, 0, casing_height - 5], rotation = [0, 0, 180]) {
        AugerHole(24, 22, 5, valve_thread_pitch) {
            color([1.0, 0, 1.0]) {
                difference() {
                    translate([0, 0, 0]) cylinder(casing_height, 13, 13, $fn=256);
                    translate([0, 0, -1]) cylinder(casing_height + 2, 11.01, 11.01, $fn=256);

                    // Allow 10mm at the bottom for the compressed spring and plug; shift up the tubing holes
                    translate([0, 0, 10]) {
                        rotate([0, 90, 45]) translate([odd ? -46 : -30, 0, -18])
                            cylinder(10, mmbore/2, mmbore/2, $fn=256);
                        rotate([0, 90, 45]) translate([odd ? -30 : -46, 0, 9])
                            cylinder(10, mmbore/2, mmbore/2, $fn=256);
                        rotate([0, 90, 135]) translate([-46, 0, -18])
                            cylinder(10, mmbore/2, mmbore/2, $fn=256);
                        rotate([0, 90, 315]) translate([-30, 0, 9])
                            cylinder(10, mmbore/2, mmbore/2, $fn=256);
                    }
                }
                
                // Flat side.
                rotate([0, 0, 45]) translate([-6.5, 9.02, 0]) cube([13, 1, casing_height]);
                rotate([0, 0, 45]) translate([-5, 9.02, 0]) cube([10, 2, casing_height]);
                rotate([0, 0, 45]) translate([-5, 9.02, 8]) cube([10, 2.8, casing_height - 16]);
                
                if (false) {
                    // Bottom threads
                    difference() {
                        ScrewThread(28, 8, pitch=valve_thread_pitch);
                        translate([0, 0, -1]) cylinder(12, 11.01, 11.01, $fn=256);
                    }
                    
                    translate([0, 0, casing_height - 8]) difference() {
                        translate([0, 0, 8]) rotate([0, 180, 0]) ScrewThread(28, 8, pitch=valve_thread_pitch);
                        translate([0, 0, -1]) cylinder(12, 11.01, 11.01, $fn=256);
                    }
                }
            }
        }
    }
}

module piston_valve_cap(valve_thread_pitch = 2, top_thickness = 2.0, valve_gap_expansion = 0.1) {

// 13
    difference() {
        union() {
            cylinder(7, 11, 11, $fn = 256);
            translate([0, 0, 5]) rotate([0, 180, 0])
                ScrewThread(24, 5, pitch=valve_thread_pitch);  // 24, 22,
            translate([0, 0, 5]) spur_gear(1, 22, top_thickness, 26);
            cylinder(8.5, 5, 5, $fn = 256);
        };
        translate([0, 0, -1]) cylinder(17, 3.5, 3.5, $fn = 256);
    };
}

module straight_tube(length, thickness = 1, bore=0.413) {
  mmbore = inches_to_mm(bore);
  difference() {
    cylinder(length, (mmbore / 2) + thickness, (mmbore / 2) + thickness, $fn=256);
    translate([0, 0, -1]) cylinder(length + 2, mmbore / 2, mmbore / 2, $fn=256);
  };
}

module tuning_slide(leading_length, slide_length, joint_length, trailing_length,
                    thickness = 2.4, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                    disassembled = false, outer_only = false, shift = 0) {
  mmbore = inches_to_mm(bore);
  slide_thickness_inches = mm_to_inches(slide_thickness);
  slide_gap_expansion_inches = mm_to_inches(slide_gap_expansion);
  
  if (!outer_only) {
      // Leading part (small size).
      straight_tube(leading_length, thickness, bore);
      
      // Interior slide part (small size, thin).
      translate([0, 0, leading_length]) straight_tube(slide_length, slide_thickness, bore);
  }
 
  exterior_hoffset = disassembled
      ? mmbore + (2 * thickness + slide_thickness + slide_gap_expansion) + 5
      : 0;
  exterior_voffset = shift + (disassembled ? 0 : leading_length);
      
  // Exterior slide part (larger size, thick).
  color([1.0, 1.0, 0.0]) translate([0, exterior_hoffset, exterior_voffset])
      straight_tube(slide_length, thickness,
                    bore + (2 * (slide_gap_expansion_inches + slide_thickness_inches)));


  // Joint (interior is standard bore; exterior is as large as exterior slide part).
  translate([0, exterior_hoffset, exterior_voffset + slide_length])
      straight_tube(joint_length,
                    thickness + (slide_thickness + slide_gap_expansion),
                    bore);
      
  // Trailing tube (normal tube).
  translate([0, exterior_hoffset, exterior_voffset + slide_length + joint_length])
      straight_tube(trailing_length, thickness, bore);
}

module valve_block(bore = 0.413, fourth_valve = true) {
  casing_height = 91.5;
  spacing = 25.4;
//  spacing = 40;
  translate([0, 0, 0]) rotate([0, 0, -45]) piston_valve_casing(0.413, false);
  translate([spacing, 0, 0]) rotate([0, 0, -45]) piston_valve_casing(0.413, true);
  translate([spacing * 2, 0, 0]) rotate([0, 0, -45]) piston_valve_casing(0.413, false);
  translate([spacing * 3, 0, 0]) rotate([0, 0, -45]) piston_valve_casing(0.413, true);

  difference() {
    union() {
      translate([9, 0, 56]) rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);
      translate([9 + (spacing), 0, 40]) rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);
      translate([9 + (spacing * 2), 0, 56])
          rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);
    }
    translate([0, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing * 2, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing * 3, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
  }
//   translate([12, 10, 10]) cube([100, 30, 50]);

  translate([0, 40, 0]) piston_valve(0.413, false);
  translate([40, 40, 0]) piston_valve(0.413, true);
  translate([80, 40, 0]) piston_valve(0.413, false);
  translate([120, 40, 0]) piston_valve(0.413, true);
  
  translate([0, -40, 0]) piston_valve_cap();
  translate([40, -40, 0]) piston_valve_cap();
  translate([80, -40, 0]) piston_valve_cap();
  translate([120, -40, 0]) piston_valve_cap();

  translate([0, -80, 0]) piston_valve_cap();
  translate([40, -80, 0]) piston_valve_cap();
  translate([80, -80, 0]) piston_valve_cap();
  translate([120, -80, 0]) piston_valve_cap();
}


bell_main_segment_inner_diameter = function(z) 15.57032 + (136.93058/(1 + (z/23.73906)));
bell_main_segment_inner_diameter_size_function = function(z) bell_main_segment_inner_diameter(337 * z);
bell_main_segment_outer_diameter_size_function =
    function(z) bell_main_segment_inner_diameter_size_function(z) + 2.0;

module bell_main_segment(bore=0.413) {
// Bell curve is modeled as:
//
// y = 15.57032 + (152.5009 − 15.57032)/(1 + (x/23.73906))
//
// up to the point where it starts curving, and is linear after that.
//
// This bit models this nonlinear curved segment (the bell flare).
// The data was taken from a 1959 Olds flugelhorn that belonged to
// my grandfather.

// This equation is returned by the function bell_main_segment_diameter.

// This needs to be converted into a set of values in the range 0..1,
// where 0 == 0 and 1 == the length of the bell segment (337).
//
// This is bell_main_segment_diameter_size_function.
//
// The circle has a radius of 0.5 to compensate for the function returning
// the diameter rather than the radius.

  difference() {
    translate([0, 0, 0])
        variable_extrude(height=200, scale=bell_main_segment_outer_diameter_size_function,
                         slices=300, $fn=1000) circle(r=0.5);
    translate([0, 0, 0])
        variable_extrude(height=200, scale=bell_main_segment_inner_diameter_size_function,
                         slices=300, $fn=1000) circle(r=0.5);
  }
//scaling the examples
//upscale=1;

//Hour Glass shape with circle and test_function_1
//translate([-15*upscale,0])scale([upscale,upscale,upscale])
//	variable_extrude(height=20, scale=bell_main_segment_diameter, slices=10,$fn=300)
//		circle(r=1);
        
        //scaling the examples
// Goes through a period of 0.1 / 6 in 20 height.


}


module bell(bore=0.413) {

// Bell measurements
// distance from end : diameter
// 0 : 153mm (at end)
// 3 : 153mm (because of curled lip; otherwise would be smaller)
// 26 : 82
// 76 : 54
// 126 : 44
// 204 : 36

// Bell segment curve is y = 16.07032 + (153.0009 − 16.07032)/(1 + (x/23.73906)
// where x is the distance from the end of the bell and y is the diameter.
//
// After subtracting 0.5mm from all diameters, curve is:
//
// y = 15.57032 + (152.5009 − 15.57032)/(1 + (x/23.73906)

bell_main_segment(bore = bore);


// 376 mm straight in is inside edge of curve.
// First curved part is ~172mm from outside at top to outside at bottom where it starts to curve.
// First curved part is ~135mm from inside to inside where it starts to curve.
// Start of curve (as measured on the inner side of curve is about 336mm to end of bell.
// Midpoint of curve is 23mm.
//
// From end of curve back to valves, slope is conical (linearly).  As best I can tell, the
// first curve is also roughly linear, to within 0.5mm after the entire lengt of the curve,
// so I will model both curves and all straight pipes other than the bell segment linearly,
// beginning from the start of the first (big) curve all the way back to the valves.
//
// Second pipe segment (after first curve) at 290mm from end of the bell: 19mm.
// Midpoint of second curve is 22mm from end of bell (outside) or 46mm (inside).
// Midpoint of second curve is 15mm in diameter.
// A valves, 12mm in diameter.

// Scale all values accordingly, because metal is thin (0.008 inches, 0.2 mm).  In fact,
// just subtract half a mm from every dimension and call that the bore.  :-)

if (0) {
fn=32;
$fn=60;

r1 = 25;
r2 = 10;
R = 40;
th = 2;

    difference()
    {
        skin([for(i=[0:fn]) 
              transform(rotation([0,180/fn*i,0])*translation([-R,0,0]), 
                        circle(r1+(r1-r2)/fn*i))]);
        for(r1 = r1-th, r2 = r2-th) {
            skin([for(i=[0:fn]) 
                  transform(rotation([0,180/fn*i,0])*translation([-R,0,0]), 
                            circle(r1+(r1-r2)/fn*i))]);
        }
    }
}
}

// valve_block();

//  translate([0, 40, 0]) piston_valve(0.413, false);
//  translate([40, 40, 0]) piston_valve(0.413, true);
//  translate([80, 40, 0]) piston_valve(0.413, false);
//  translate([120, 40, 0]) piston_valve(0.413, true);

// First valve slide: Out 22mm at 20 degrees, curve down.  53mm from top of top hole to
//                    tuning slide joint (21mm usable).  15mm interior.  10mm overlap.
//                    12mm from overlap to middle of curve.  20mm between outside of one
//                    tube and outside of next tube (e.g. left to left or right to right).
//                    10mm joint.  21mm slide segment.  Curve back to valve.
// Second valve slide: 9mm inner slide, 14mm slide joint to casing, 7mm overlap,
//                     ~12mm to middle of arc, or a little less because of narrower gap.
// Third valve slide: Same as first, but 28mm between slides, 104mm from top of top hole
//                    to slide gap on long side, 69mm interior slide length.


// piston_valve_cap();

bell();

// translate([0, 0, 21.5]) piston_valve(0.413, false);

// translate([0, 40, 0]) piston_valve(0.413, false);
// piston_valve_casing(0.413, false);

// translate([40, 0, 0]) piston_valve_cap();
// translate([40, 40, 0]) piston_valve_cap();

// translate([-30, -30, 0]) tuning_slide(10, 20, 10, 10, disassembled = true, shift = 0);

// translate([-50, -50, 0]) small_morse_receiver(disassembled = true);
