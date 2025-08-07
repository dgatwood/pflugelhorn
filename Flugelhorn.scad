
// https://github.com/rcolyer/threads-scad
use <threads-scad/threads.scad>

// https://github.com/chrisspen/gears
use <gears/gears.scad>

// https://github.com/openscad/scad-utils.git
use <scad-utils/transformations.scad>
use <scad-utils/shapes.scad>

// https://github.com/openscad/list-comprehension-demos
use <list-comprehension-demos/skin.scad>


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
 
global_in_place = true;
 
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

  // The lead pipe has to slide into something.
  outer_pipe_inner_diameter = (outer_tube_radius + slide_gap_expansion) * 2;
  outer_pipe_outer_diameter = outer_pipe_inner_diameter + (thickness_in_mm * 2);

  final_external_radius = outer_tube_radius / 2;
  if (tuning) {
    offset = (outer_pipe_outer_diameter / 2) - (2 * thickness_in_mm);
    translate([0, disassembled ? 30 : 0, disassembled ? 0 : 10]) {
      color([1, .5, .5]) {
        difference() {
          union() {
            cylinder(lead_pipe_length_in_mm - 10, outer_pipe_outer_diameter / 2,
                     outer_pipe_outer_diameter / 2, $fn = 256);
            straight_tube(lead_pipe_length_in_mm - 10, 1.0,
                          mm_to_inches(outer_pipe_inner_diameter));
            translate([-4, outer_tube_radius - 3, 0]) cube([3, 11, 8]);
            translate([1, outer_tube_radius - 3, 0]) cube([3, 11, 8]);
            rotate([0, 0, 15]) {
              difference() {
                translate([offset, -8, 26]) cube([32.35 + (2 * thickness_in_mm), 4, 33]);
                translate([offset + (2 * thickness_in_mm) + 17.35, 0, 48.9]) {
                    rotate([90, 0, 0]) cylinder(10, 2, 2, $fn = 256);
                }
              }
            }
          }
          // Screw hole.
          translate([-5, outer_tube_radius + 4.5, 4]) {
              rotate([0, 90, 0]) cylinder(10, 2, 2, $fn = 256);
          }
          // Slot for tightening the tube..
          translate([-1, outer_tube_radius - 2, -1]) cube([2, 5, 15]);
          translate([0, 0, -1]) cylinder(lead_pipe_length_in_mm + 2,
                                         outer_pipe_inner_diameter / 2,
                                         outer_pipe_inner_diameter / 2, $fn = 256);
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
 * @param even                 Odd-numbered valves and even-numbered valves
 *                             alternate between the inlet and outlet being
 *                             at the top and bottom and vice-versa.
 * @param valve_gap_expansion  Adjust this based on your 3D printer so
 *                             that the valve moves freely
 *                             without leaking.
 */
module piston_valve(bore=0.413, even=true, valve_gap_expansion = 0.1) {
  mmbore = inches_to_mm(bore);
  difference() {
    piston_valve_raw(valve_gap_expansion);
    translate([0, 0, 62.5]) cylinder(8, 1.65, 1.65, $fn = 256);  // 3.3mm bore hole to tap an m4 screw for the valve stem.
    
    // To/from valve slide - top (L-bores)
    translate([10, 0, even ? 46 : 30]) rotate_extrude(angle=360) translate([8, 0, 0]) circle(mmbore / 2);
    translate([0, -11, even ? 30 : 46]) rotate_extrude(angle=360) translate([8, 0, 0]) circle(mmbore / 2);

    // Slant bore (in to out)
    rotate([0, 0, even ? 0 : 180]) {
        translate([0, 0, even ? -16.5 : -28.5]) {
            translate([-8, -8, even ? 38 : 50]) rotate([-90, 35, 45]) rotate_extrude(angle=90) translate([8, 0, 0]) circle(mmbore / 2);
            rotate([0, 0, 180]) translate([-8, -8, even ? 38 : 50]) rotate([90, -35, 45]) rotate_extrude(angle=90) translate([8, 0, 0]) circle(mmbore / 2);
            translate([-4, -4.5, even ? 31.5 : 43.5]) rotate([-32, 32, -3])
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
    if (even) {
      translate([0, -15, 14]) rotate([20, -35, 45]) cube([30, 30, 2]);
    } else {
      translate([0, -25, 28]) rotate([27, 35, 45]) cube([30, 30, 2]);
    }
    piston_valve_raw(valve_gap_expansion);
  }
}

module piston_valve_casing(bore=0.413, number=1, valve_thread_pitch = 2) {
    casing_height = 101.5;
    even = (number % 2) == 0;

    rotate([0, 0, -45]) {
        mmbore = inches_to_mm(bore);
        AugerHole(24, 22, 5, valve_thread_pitch, position = [0, 0, casing_height - 5], rotation = [0, 0, 180]) {
            AugerHole(24, 22, 5, valve_thread_pitch) {
                color([1.0, 0, 1.0]) {
                    difference() {
                        union() {
                            translate([0, 0, 0]) cylinder(casing_height, 13, 13, $fn=256);
                            rotate([0, 0, 45]) {
                                if (number == 1) {
                                  first_valve_tubing();
                                } else if (number == 2) {
                                  second_valve_tubing();
                                } else if (number == 3) {
                                  third_valve_tubing();
                                } else if (number == 4) {
                                  fourth_valve_tubing();
                                }
                            }
                        }
                        translate([0, 0, -1]) cylinder(casing_height + 2, 11.01, 11.01, $fn=256);

                        // Allow 10mm at the bottom for the compressed spring and plug; shift up the tubing holes
                        translate([0, 0, 10]) {
                            rotate([0, 90, 45]) translate([even ? -46 : -30, 0, -18])
                                cylinder(10, mmbore/2, mmbore/2, $fn=256);
                            rotate([0, 90, 45]) translate([even ? -30 : -46, 0, 9])
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

module straight_tube(length, thickness = 2.0, bore=0.413) {
  sloped_tube(length, thickness, bore, bore);
}

module sloped_tube(length, thickness = 2.0, bore_1=0.413, bore_2=0.413) {
  mmbore_1 = inches_to_mm(bore_1);
  mmbore_2 = inches_to_mm(bore_2);
  difference() {
    cylinder(length, (mmbore_1 / 2) + thickness, (mmbore_2 / 2) + thickness, $fn=256);
    translate([0, 0, -1]) cylinder(length + 2, mmbore_1 / 2, mmbore_2 / 2, $fn=256);
  };
}

module tuning_slide(leading_length, slide_length, joint_length, trailing_length,
                    thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                    disassembled = false, inner_only = false, outer_only = false, shift = 0) {
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

  if (!inner_only) {
      // Exterior slide part (larger size, thick).
      color([1.0, 1.0, 0.0]) translate([0, exterior_hoffset, exterior_voffset])
          straight_tube(slide_length, slide_thickness,
                        bore + (2 * (slide_gap_expansion_inches + slide_thickness_inches)));


      // Joint (interior is standard bore; exterior is as large as exterior slide part).
      translate([0, exterior_hoffset, exterior_voffset + slide_length])
          straight_tube(joint_length,
                        slide_thickness + (slide_thickness + slide_gap_expansion),
                        bore);
          
      // Trailing tube (normal tube).
      translate([0, exterior_hoffset, exterior_voffset + slide_length + joint_length])
          straight_tube(trailing_length, thickness, bore);
    }
}

module first_valve_tubing(bore = 0.413, thickness = 2) {
  // First valve slide: Out 22mm at 20 degrees (to outside of curve), curve down.
  //                    53mm from top of top hole to
  //                    tuning slide joint (21mm usable).  15mm interior.  10mm overlap.
  //                    12mm from overlap to middle of curve.  20mm between outside of one
  //                    tube and outside of next tube (e.g. left to left or right to right).
  //                    10mm joint.  21mm slide segment.  Curve back to valve.

  mmbore = inches_to_mm(bore);

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -10, 56]) rotate([90, 0, 0]) {
    straight_tube(3, bore=bore);
    translate([-9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 135,
                    end_degrees = 180, reversed = true); 
    }
    translate([-9.9, 0, 1.5]) rotate([0, -45, 0]) {
        translate([10, -10, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }
    
    // 53mm to top of top hole
    // 5.2 on y would be aligned with top of hole
    translate([-9.9, -53, 36.2]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 16, joint_length = 5, trailing_length = 22,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }
    
    // Tuning slide goes here.
    if (global_in_place) {
      translate([10.1, -63, 15.7]) rotate([-90, 0, 0]) first_valve_slide();
    }
    
    translate([10.1, -53, 36.2]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 16, joint_length = 5, trailing_length = 6,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }
    translate([10.1, 4, 1.5]) rotate([0, 45, 0]) {
        translate([-10, -30, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }
    
    translate([10.1, -16, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 45, reversed = true); 
    }
    
    translate([0, -16, 0]) straight_tube(3, bore=bore);
  }
}

module first_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10, trailing_length = 10,
               thickness = thickness, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-10, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-20, 0, 0])
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10, trailing_length = 10,
                   thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                   disassembled = false, inner_only = true, outer_only = false, shift = 0);
}

module second_valve_tubing(bore = 0.413) {
  // Second valve slide: 9mm inner slide, 14mm slide joint to casing, 7mm overlap,
  //                     ~12mm to middle of arc, or a little less because of narrower gap.
  mmbore = inches_to_mm(bore);

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -10, 56]) rotate([90, 0, 0]) {
    straight_tube(3, bore=bore);

    translate([0, 0, 28]) rotate([180, 0, 0]) {
      // 15mm outside, 9mm inner slide length (10).
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 4, trailing_length = 1,
                   thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                   disassembled = false, inner_only = false, outer_only = true, shift = 0);
    }

    // Tuning slide goes here.
    if (global_in_place) {
      translate([0, 0, 28.1]) rotate([0, 180, -90]) second_valve_slide();
    }

    translate([0, -16, 28]) rotate([180, 0, 0]) {
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 4, trailing_length = 1,
                   thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                   disassembled = false, inner_only = false, outer_only = true, shift = 0);
    }

    translate([0, -16, 0]) straight_tube(3, bore=bore);
  }
}

module second_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10, trailing_length = 10,
               thickness = thickness, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-8, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 8,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-16, 0, 0]) {
    tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10, trailing_length = 10,
                 thickness = thickness, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                 disassembled = false, inner_only = true, outer_only = false, shift = 0);
  }
}

module third_valve_tubing(bore = 0.413, thickness = 2) {
  // Third valve slide: Same as first, but 28mm between slides, 104mm from top of top hole
  //                    to slide gap on long side, 68mm interior slide length.
  // First valve slide: Out 22mm at 20 degrees (to outside of curve), curve down.
  //                    53mm from top of top hole to
  //                    tuning slide joint (21mm usable).  15mm interior.  10mm overlap.
  //                    12mm from overlap to middle of curve.  20mm between outside of one
  //                    tube and outside of next tube (e.g. left to left or right to right).
  //                    10mm joint.  21mm slide segment.  Curve back to valve.
  // Add 5mm to both straight parts because the existence of the fourth valve precludes making
  // the fourth slide wider without doing anything weird.

  mmbore = inches_to_mm(bore);

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -10, 56]) rotate([90, 0, 0]) {
    straight_tube(3, bore=bore);
    translate([-9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 135,
                    end_degrees = 180, reversed = true); 
    }
    translate([-9.9, 0, 1.5]) rotate([0, -45, 0]) {
        translate([10, -10, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }
    
    // 53mm to top of top hole  -- 109
    // 5.2 on y would be aligned with top of hole
    translate([-9.9, -109, 36.2]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 68, joint_length = 5, trailing_length = 26,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }
    
    // Tuning slide goes here.
    if (global_in_place) {
      translate([10.1, -119, 15.7]) rotate([-90, 0, 0]) third_valve_slide();
    }
    
    translate([10.1, -109, 36.2]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 68, joint_length = 5, trailing_length = 10,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }
    translate([10.1, 4, 1.5]) rotate([0, 45, 0]) {
        translate([-10, -30, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }
    
    translate([10.1, -16, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 45, reversed = true); 
    }
    
    translate([0, -16, 0]) straight_tube(3, bore=bore);
  }
}

module third_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 68, joint_length = 10, trailing_length = 10,
               thickness = thickness, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-10, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-20, 0, 0])
      tuning_slide(leading_length = 10, slide_length = 68, joint_length = 10, trailing_length = 10,
                   thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1, bore=0.413,
                   disassembled = false, inner_only = true, outer_only = false, shift = 0);
}

module fourth_valve_tubing(bore = 0.413, thickness = 2) {
  // No measurements to work with, so guess.
  mmbore = inches_to_mm(bore);

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -10, 56]) rotate([90, 0, 0]) {
    straight_tube(3, bore=bore);
    translate([9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true); 
    }
    
    // Estimated total length: 150mm + 275mm = 425mm
    translate([9.9, 0, 11.5]) rotate([0, 90, 0]) {
        straight_tube(40, bore = bore);
    }
    translate([49.9, -10, 11.5]) rotate([-90, 180, 0]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true); 
    }
    
    translate([59.9, -10, 11.5]) rotate([90, 0, 0]) {
        straight_tube(16, bore = bore);
    }


    
    // Tuning slide here
    
    
    
    
    translate([0, -25.9, 1.5]) rotate([0, 0, -90]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true); 
    }

    translate([0, -16, 0]) straight_tube(3, bore=bore);
  }
}

module fourth_valve_slide(bore = 0.413, thickness = 2) {

}

module valve_block(bore = 0.413, fourth_valve = true) {
  casing_height = 91.5;
  spacing = 25.4;
//  spacing = 40;
  translate([0, 0, 0]) piston_valve_casing(0.413, number = 1);
  translate([spacing, 0, 0]) piston_valve_casing(0.413, number = 2);
  translate([spacing * 2, 0, 0]) piston_valve_casing(0.413, number = 3);
  translate([spacing * 3, 0, 0]) piston_valve_casing(0.413, number = 4);  

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
  // Valve mount
  difference() {
    translate([17.5, 10, 63.35]) cube([40, 13.5, 5]);
    translate([38, 19.275, 60]) rotate([0, 0, 90]) cylinder(30, 2, 2, $fn=256);
  }
}

module valve_parts(bore = 0.413) {
  translate([0, 40, 0]) piston_valve(bore, false);
  translate([40, 40, 0]) piston_valve(bore, true);
  translate([80, 40, 0]) piston_valve(bore, false);
  translate([120, 40, 0]) piston_valve(bore, true);
  
  translate([0, -40, 0]) piston_valve_cap();
  translate([40, -40, 0]) piston_valve_cap();
  translate([80, -40, 0]) piston_valve_cap();
  translate([120, -40, 0]) piston_valve_cap();

  translate([0, -80, 0]) piston_valve_cap();
  translate([40, -80, 0]) piston_valve_cap();
  translate([80, -80, 0]) piston_valve_cap();
  translate([120, -80, 0]) piston_valve_cap();
}


bell_main_segment_inner_radius = function(z) (15.57032 + (136.93058/(1 + (z/23.73906)))) / 2;
bell_main_segment_slope = function(z) -406325468068.5 / (((50000 * z) + 1186953)^2);

module bell_main_segment(bore=0.413, start_slice = 0, stop_slice = undef, height = 337, thickness = 2.0) {
  // This function models the nonlinear curved segment of the bell (the bell flare).
  // These measurements were taken from a 1959 Olds flugelhorn that belonged to
  // my grandfather.  They are the exterior diameter of the bell.
  //
  // Distance from end of bell : diameter
  //
  // 0 : 153mm (at end)
  // 3 : 153mm (because of curled lip; otherwise would be smaller)
  // 26 : 82
  // 76 : 54
  // 126 : 44
  // 204 : 36
  //
  // The main part of the bell's diameter is modeled as:
  //
  // y = 16.07032 + (153.0009 − 16.07032)/(1 + (x/23.73906)
  //
  // where x is the distance from the end of the bell and y is the diameter.
  //
  // This curve fits the dimensions of the ouside of the bell up to the point
  // where it starts curving.  The slope of the exterior of the tube is linear
  // after that.
  //
  // After subtracting 0.5mm from all diameters, the curve becomes:
  //
  // y = 15.57032 + (152.5009 − 15.57032)/(1 + (x/23.73906)  
  //
  // This equation is returned (after dividing by two) by the function
  // bell_main_segment_radius.
    slices = height;
    sliceHeight = height/slices;
    actual_stop_slice = (stop_slice == undef) ? slices : stop_slice;

    union() {
        for(slice = [start_slice : actual_stop_slice - 1]){
            zOffset = sliceHeight * slice;
            nextZOffset = sliceHeight * (slice + 1);

            translate([0, 0, zOffset]) {
                difference() {
                    // This is what this code is effectively doing:
                    //
                    //     baseSlope = bell_main_segment_slope(zOffset);
                    //     bottomSlopeDegrees = 90 + (atan(baseSlope));
                    //     oppositeOverHypotenuseAtBottom = sin(bottomSlopeDegrees);
                    //
                    // The opposite is the thickness of the bell (e.g. 2mm).
                    // This is a fixed constant.
                    //
                    // The hypotenuse is the difference between the inner wall
                    // and the outer wall at that height.  At points where the
                    // bell is almost horizontal, this is much wider than the
                    // thickness, because you're measuring through the bell
                    // at a steep angle.
                    //
                    // What we need from there is the denominator of this fraction, so
                    // flip the fraction, then multiply by the desired thickness value.
                    //
                    //     hypotenuseOverOppositeAtBottom = 1/oppositeOverHypotenuseAtBottom;
                    //     widthAtBottom = hypotenuseOverOppositeAtBottom * thickness;
                    //
                    // We can simplify this computation further:
                    //
                    //     hypotenuseOverOppositeAtBottom = 1/sin(90 + atan(baseSlope));
                    //     hypotenuseOverOppositeAtBottom = secant(90 + atan(baseSlope));
                    //     hypotenuseOverOppositeAtBottom = cosecant(atan(baseSlope));
                    //     hypotenuseOverOppositeAtBottom = sqrt((baseSlope ^2) + 1);
                    baseSlope = bell_main_segment_slope(zOffset);
                    widthAtBottom = sqrt((baseSlope ^2) + 1) * thickness;

                    // This math is identical to the above, but computed at the top of the cylinder.
                    //
                    // topSlopeDegrees = 90 + (atan(topSlope));
                    // oppositeOverHypotenuseAtTop = sin(topSlopeDegrees);  // = thickness / length
                    // hypotenuseOverOppositeAtTop = 1/oppositeOverHypotenuseAtTop;
                    // widthAtTop = hypotenuseOverOppositeAtTop * thickness;
                    topSlope = bell_main_segment_slope(nextZOffset);
                    widthAtTop = sqrt((topSlope ^2) + 1) * thickness;
                    
                    cylinder(sliceHeight, bell_main_segment_inner_radius(zOffset) + widthAtBottom,
                             bell_main_segment_inner_radius(nextZOffset) + widthAtTop, $fn = 256);
                    cylinder(sliceHeight, bell_main_segment_inner_radius(zOffset),
                             bell_main_segment_inner_radius(nextZOffset), $fn = 256);
                }
            }
        }
    }
    translate([0, 0, 2.0]) {
        rotate_extrude($fn = 256) {
            translate([bell_main_segment_inner_radius(0) + (thickness / 2.0), 0, 0])
                circle(2.0, $fn = 256);
        }
    }
    if (actual_stop_slice > 310) {
        rotate([0, 0, 15]) {
            translate([-2.5, -26, 260]) { 
                difference() {
                    // Valve mount
                    rotate([-1.1, 0, 0]) cube([5, 11, 50]);
                    translate([-20, 6, 25]) rotate([0, 90, 0]) cylinder(60, 2, 2, $fn=256);
                }
            }
        }
    }
}

module bell_big_curve(bore=0.413, thickness = 2.0) {
    // Length of the outside of the tube is 2 * pi * (bend_radius + radius_1).
    
    bend_radius = 76;
    
    // At 337mm from end of bell, interior radius is 12.29mm.  Add thickness.
    // At other end of curve, 19mm diameter, 9.5mm radius.
    curved_tube(slices = 100, radius_1 = 12.29 + thickness,
                radius_2 = 9.5 + thickness, bend_radius = bend_radius,
                thickness = thickness, enable_brace = true);                   
}

module bell_small_curve(bore=0.413, thickness = 2.0) {
    // Length of the outside of the tube is 2 * pi * (bend_radius + radius_1).
    
    // At opposite ends, 17mm and 14mm approximate inner diameter,
    // 8.5mm and 7mm inner radius.
    //
    // Original instrument is 130mm between the outer sides of the tubes,
    // and 102mm between the inner sides of the tubes, as measured near the
    // bell end, so the diameter of the bend is halfway between, or 116mm.
    // The radius is therefore about 58mm.

    curved_tube(slices = 100, radius_1 = 8.5 + thickness,
                radius_2 = 7 + thickness, bend_radius = 58,
                thickness = thickness);
}
    
module curved_tube(bore=0.413, thickness = 2.0, radius_1 = 10,
                   radius_2 = 20, bend_radius = 40, thickness = 2,
                   slices = 100, enable_brace = false, start_degrees = 0,
                   end_degrees = 180,
                   reversed = false) {
    midwidth = radius_1 - (radius_1-radius_2)/2;
    difference()
    {
        union() {
            skin([for(i=[0:slices], $fn = 256)
                  transform(rotation([0, start_degrees + ((end_degrees - start_degrees) / slices * i), 0]) *
                            translation([-bend_radius, 0, 0]), 
                            circle(radius_1 - (radius_1 - radius_2) / slices * i), $fn = 256)]);
            if (enable_brace) {
                translate([-25, -5, bend_radius - midwidth - 20]) cube([30, 10, 20 + midwidth]);
                translate([-25, -21.6, bend_radius - midwidth - 20]) cube([30, 21.6, 20 + midwidth]);   
            }
        }

        for(radius_1 = radius_1-thickness, radius_2 = radius_2-thickness) {
            skin([for(i=[0:slices], $fn = 256) 
                  transform(rotation([0, start_degrees + ((end_degrees - start_degrees) / slices * i), 0]) *
                            translation([-bend_radius, 0, 0]), 
                            circle(radius_1 - (radius_1 - radius_2) / slices * i), $fn = 256)]);
        }
        translate([-10, 20, bend_radius - midwidth - 10]) {
            rotate([90, 0, 0]) cylinder(60, 2, 2, $fn = 256);
        }
    }
}

module bell(bore=0.413, thickness = 2.0) {
    bell_length = 337;
    bell_main_segment(bore = bore, height = bell_length, thickness = thickness);
    translate([76, 0, bell_length]) bell_big_curve(bore = bore, thickness = thickness);
    
    id_2 = 19;
    id_2_inches = mm_to_inches(id_2);
    id_1 = 17;
    id_1_inches = mm_to_inches(id_1);
    
    translate([152, 0, 121]) sloped_tube(216, thickness = 2, bore_1 = id_1_inches,
                                         bore_2 = id_2_inches);
    translate([96.00, -15, 121]) rotate([0, 180, 15]) bell_small_curve(bore = bore, thickness = thickness);
    // Top is at 430 or so.  Bottom should be about 54.  This block lets us measure.
    // translate([100, -5, 44]) cube([10, 10, 10]);
    
    id_3 = 14;
    id_3_inches = mm_to_inches(id_3);
    id_4 = 12;
    id_4_inches = mm_to_inches(id_4);
    
    translate([40, -30, 121]) sloped_tube(115, thickness = 2, bore_1 = id_3_inches,
                                         bore_2 = id_4_inches); 


    
// 400mm end of bell to outer edge of first curve.
// 372mm end of curve to end of curve (outer).

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
// Second pipe segment (after first curve) at 290mm from end of the bell: 19mm in diameter.
// Midpoint of second curve is 22mm from end of bell (outside) or 46mm (inside).
// Midpoint of second curve is 15mm in diameter.
// 14mm at small side.
// 17mm at large side.
// A valves, 12mm in diameter.

// Scale all values accordingly, because metal is thin (0.008 inches, 0.2 mm).  In fact,
// just subtract half a mm from every dimension and call that the bore.  :-)


}

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

module spit_valve() {
  // Designed for a 1/4" x 7/8" stretch spring (Amazon ASIN B097R78LN2).
  // Also used Amazon ASIN B0DCGJ65QC for valve springs, but they're too strong.
  // Look for something else.
  
}

// piston_valve_cap();

// Build instrument in place
if (false) {
    bell();
    translate([78.6, -19.6, 247]) rotate([0, -90, 15]) valve_block();
    translate([39.6, -29.6, 449]) rotate([0, 180, -165]) small_morse_receiver(disassembled = false);
} else {
    valve_block();
    // valve_parts();
    // piston_valve_cap();
}

// translate([0, 0, 21.5]) piston_valve(0.413, false);

// translate([0, 40, 0]) piston_valve(0.413, false);
// piston_valve_casing(0.413, false);

// translate([40, 0, 0]) piston_valve_cap();
// translate([40, 40, 0]) piston_valve_cap();

// translate([-30, -30, 0]) tuning_slide(10, 20, 10, 10, disassembled = true, shift = 0);

// translate([-50, -50, 0]) small_morse_receiver(disassembled = true);
