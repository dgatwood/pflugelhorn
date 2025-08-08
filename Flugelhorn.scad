
// https://github.com/rcolyer/threads-scad
use <threads-scad/threads.scad>

// https://github.com/chrisspen/gears
use <gears/gears.scad>

// https://github.com/openscad/scad-utils.git
use <scad-utils/transformations.scad>
use <scad-utils/shapes.scad>

// https://github.com/openscad/list-comprehension-demos
use <list-comprehension-demos/skin.scad>

// Assembly notes: Valve tolerances must be tight or the instrument will be
// unplayable.  To deal with this, you will need to lap the valves as follows:
//
// 1.  Apply a thick coating of Plastruct Plastic weld to the valve.
// 2.  About half a minute after you finish, use acetone with a paper towel
//     to clean off the solvent/glue that you just added.
// 3.  Wash the valve with dish detergent.
// 4.  Perform three sanding passes with 400-grit emery cloth — two passes
//     vertically down the length of the valve and one pass in small circles.
//     In each pass, sand until not obviously sticky.  Wash with dish
//     detergent between passes.
// 5.  Allow the valves to dry.  If they are still sticky after an hour,
//     do another sanding and washing pass.  Repeat until not sticky.
//
// Note that these instructions assume PLA.  Other materials may vary.

// To do list:
//
// 1.  Fix leaky valves.
// 2.  Fix lead pipe so that the gap closes by making the outer tube slightly smaller inside.
// 3.  Check valve slides for 1, 3, and 4, and if necessary, reduce width by 0.02mm.
// 4.  Split main part of the bell for people whose printers can't print
//     something that tall (337mm).
// 5.  Reenable valve_parts() when I'm done tweaking things.

/*
 * Note that unless otherwise noted, all dimensions are in mm except for
 * bore, which is in inches, because that is how musical instrument bore
 * sizes are traditionally measured.
 */

// 0 == Whole instrument (slow, useless for printing).
// 1 == Valve section.
// 2 == Valves and caps.
// 3 == Bell parts.
// 4 == Spit valve lever.
// 5 == Tuning slides.
// 6 == Mouthpiece receiver.
// 7 == Valve measurement casing (for aid in knowning whether to sanding curved part of valves or just flat side)
global_build_group = 1;
high_quality = false;

casing_height = 101.5;  // Do not modify.
global_in_place = (global_build_group == 0);  // Do not modify.

function inches_to_mm(inches) = inches * 25.4;
function mm_to_inches(mm) = mm / 25.4;
function MAX(a, b) = ((a < b) ? b : a);
function MIN(a, b) = ((a < b) ? a : b);

/**
 * Creates a receiver and lead pipe with the specified taper and length.
 *
 * @param outer_diameter_inches     The outer diameter of the mouthpiece at the
 *                                  large end of its taper.
 * @param taper_in_inches_per_inch  The amount that the mouthpiece diameter
 *                                  decreases per inch.
 * @param taper_length_in_inches    The total length of the mouthpiece taper.
 * @param lead_pipe_length_in_mm    The length of the entire lead pipe, including
 *                                  the receiver.
 * @param bore                      The expected tubing bore at the far end of
 *                                  the lead pipe.
 * @param thickness_in_mm           The minimum thickness for the tubing.
 * @param slide_gap_expansion       A gap between the lead pipe inner part and outer
 *                                  part to reduce the need for sanding.
 * @param outer_thickness_expansion Increase to the thickness of the outer pipe so that
 *                                  its outer diameter is constant.  This is to avoid
 *                                  having to reprint the valve block when you adjust
 *                                  slide_gap_expansion.
 * @param nubs                      True to include nubs on the outside for easier
 *                                  tuning (if the lead pipe is used for tuning).
 */
module receiver(outer_diameter_inches, taper_in_inches_per_inch, taper_length_in_inches,
                lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.1,
                outer_thickness_expansion = 0.25,
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
  outer_pipe_outer_diameter = outer_pipe_inner_diameter +
                              ((outer_thickness_expansion + thickness_in_mm) * 2);

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


            translate([-3.5, outer_tube_radius - 3, 0]) cube([2, 11, 8]);
            translate([1.5, outer_tube_radius - 3, 0]) cube([2, 11, 8]);

            // Attachment plate
            translate([-7.7, 0, 0]) rotate([0, 0, 15]) {
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
          translate([-1.5, outer_tube_radius - 2, -1]) cube([3, 5, 15]);

          // Screw hole
          translate([0, 0, -1]) cylinder(lead_pipe_length_in_mm + 2,
                                         outer_pipe_inner_diameter / 2,
                                         outer_pipe_inner_diameter / 2, $fn = 256);
        }
      }
    }
  }
}

module receiver_coupler(outer_diameter_inches, slide_gap_expansion = 0.2, thickness_in_mm = 2.4, bore = 0.413) {
  mouthpiece_outer_diameter = inches_to_mm(outer_diameter_inches);
  mmbore = inches_to_mm(bore);
  outer_tube_radius = MAX((mouthpiece_outer_diameter + thickness_in_mm) / 2,
                          ((mmbore + thickness_in_mm) / 2));
  outer_pipe_inner_diameter = (outer_tube_radius + slide_gap_expansion) * 2;
  outer_pipe_outer_diameter = outer_pipe_inner_diameter + (thickness_in_mm * 2);

  coupler_inner_diameter = outer_pipe_outer_diameter + 0.2;

  straight_tube(30, bore = mm_to_inches(coupler_inner_diameter), thickness = 3.0);
}

/* A receiver for a standard large morse taper (cornet-style) flugelhorn mouthpiece. */
module large_morse_receiver(lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.05,
                bore = 0.413, thickness_in_mm = 2.4, nubs = true, tuning = true,
                disassembled = false) {
  receiver(0.4350, 0.05, 1.1, lead_pipe_length_in_mm = lead_pipe_length_in_mm,
           slide_gap_expansion = slide_gap_expansion, bore = bore,
           thickness_in_mm = thickness_in_mm, nubs = nubs, tuning = tuning,
           disassembled = disassembled);
}

module large_morse_receiver_coupler(slide_gap_expansion = 0.2, bore = 0.413, thickness_in_mm = 2.4) {
  receiver_coupler(0.4350, slide_gap_expansion = slide_gap_expansion, bore = bore,
           thickness_in_mm = thickness_in_mm);
}

module small_morse_receiver_coupler(slide_gap_expansion = 0.2, bore = 0.413, thickness_in_mm = 2.4) {
  receiver_coupler(0.395, slide_gap_expansion = slide_gap_expansion, bore = bore,
           thickness_in_mm = thickness_in_mm);
}

module small_morse_receiver(lead_pipe_length_in_mm = 114, slide_gap_expansion = 0.05,
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
 * @param valve_gap_expansion The amount to shrink or expand the valve to compensate
 *                            for inaccuracy in the size of the model.
 */
module piston_valve_raw(valve_gap_expansion = 0.01) {
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
module piston_valve(bore=0.413, valve_gap_expansion = 0.01, number = 1) {
  odd = ((number % 2) != 0);
  mmbore = inches_to_mm(bore);
  difference() {
    piston_valve_raw(valve_gap_expansion);
    translate([0, 0, 62.5]) cylinder(8, 1.65, 1.65, $fn = 256);  // 3.3mm bore hole to tap an m4 screw for the valve stem.

    // To/from valve slide - top (L-bores)
    translate([10, 0, odd ? 46 : 30]) rotate_extrude(angle=360, $fn=256)
        translate([8, 0, 0]) circle(mmbore / 2, $fn=256);
    translate([0, -11, odd ? 30 : 46]) rotate_extrude(angle=360, $fn=256)
        translate([8, 0, 0]) circle(mmbore / 2, $fn=256);

    // Slant bore (in to out)
    rotate([0, 0, odd ? 0 : 180]) {
        translate([0, 0, odd ? -16.5 : -28.5]) {
            translate([-8, -8, odd ? 38 : 50]) rotate([-90, 35, 45])
                rotate_extrude(angle=90, $fn=256) translate([8, 0, 0]) circle(mmbore / 2, $fn=256);
            rotate([0, 0, 180]) translate([-8, -8, odd ? 38 : 50]) rotate([90, -35, 45])
                rotate_extrude(angle=90, $fn=256) translate([8, 0, 0]) circle(mmbore / 2, $fn=256);
            translate([-4, -4.5, odd ? 31.5 : 43.5]) rotate([-32, 32, -3])
                cylinder(18, mmbore/2, mmbore/2, $fn = 256);
        };
    }

    // Indent in bottom for valve oil
    translate([0, 0, -1]) cylinder(6, 9, 9, $fn = 256);

    // Vented valve
    rotate([25, 25, 0]) cylinder(20, 2, 2, $fn = 256);

    // Valve number stamp
    translate([0, 0, 65]) linear_extrude(6) rotate([0, 0, 45]) translate([2, -3.5, 0]) text(text = str(number), size = 8);
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

module piston_valve_casing(bore=0.413, number=1, valve_thread_pitch = 2, for_measurement = false) {
    even = (number % 2) == 0;

    rotate([0, 0, -45]) {
        mmbore = inches_to_mm(bore);
        AugerHole(24, 22, 5, valve_thread_pitch, position = [0, 0, casing_height - 5], rotation = [0, 0, 180]) {
            AugerHole(24, 22, 5, valve_thread_pitch) {
                color([1.0, 0, 1.0]) {
                    difference() {
                        union() {
                            difference() {
                              translate([0, 0, 0]) cylinder(casing_height, 13, 13, $fn=256);

                              // Bore holes for the valve tubing and tubes between the valves.
                              // Allow 10mm at the bottom for the compressed spring and plug; shift up the tubing holes
                              translate([0, 0, 10]) {
                                  rotate([0, 90, 45]) translate([even ? -46 : -30, 0, -18])
                                      cylinder(18, mmbore/2, mmbore/2, $fn=256);
                                  rotate([0, 90, 45]) translate([even ? -30 : -46, 0, 9])
                                      cylinder(10, mmbore/2, mmbore/2, $fn=256);
                                  rotate([0, 90, 135]) translate([-46, 0, -18])
                                      cylinder(10, mmbore/2, mmbore/2, $fn=256);
                                  rotate([0, 90, 315]) translate([-30, 0, 9])
                                      cylinder(10, mmbore/2, mmbore/2, $fn=256);
                              }
                            }
                            if (!for_measurement) {
                              rotate([0, 0, 45]) {
                                  if (global_in_place || true) {
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
                            }
                        }
                        translate([0, 0, -1]) cylinder(casing_height + 2, 11/*.01*/, 11/*.01*/, $fn=256);
                    }

                    if (!for_measurement) {
                      // Flat side.
                      rotate([0, 0, 45]) translate([-6.5, 9/*.02*/, 0]) cube([13, 1, casing_height]);
                      rotate([0, 0, 45]) translate([-5, 9/*.02*/, 0]) cube([10, 2, casing_height]);
                      rotate([0, 0, 45]) translate([-5, 9/*.02*/, 8]) cube([10, 2.8, casing_height - 16]);
                    }
                }
            }
        }
    }
}

module piston_valve_cap(valve_thread_pitch = 2, top_thickness = 2.0) {

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
                    thickness = 2, slide_thickness = 1, slide_gap_expansion = 0.1,
                    thickness_compensation = 0.05, bore=0.413,
                    disassembled = false, inner_only = false, outer_only = false,
                    shift = 0) {
  mmbore = inches_to_mm(bore);
  slide_thickness_inches = mm_to_inches(slide_thickness);
  slide_gap_expansion_inches = mm_to_inches(slide_gap_expansion);

  if (!outer_only) {
      // Leading part (small size).
      straight_tube(leading_length, thickness, bore);

      // Interior slide part (small size, thin).
      translate([0, 0, leading_length])
          straight_tube(slide_length, slide_thickness + thickness_compensation, bore);
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
  translate([0.1, -10, 56]) rotate([90, 0, 0]) {
    translate([0.1, 0, 0]) straight_tube(3, bore=bore);
    translate([-9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 135,
                    end_degrees = 180, reversed = true);
    }
    translate([-9.9, 0, 1.49]) rotate([0, -45, 0]) {
        translate([10, -10, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }

    // 53mm to top of top hole
    // 5.2 on y would be aligned with top of hole
    translate([-9.9, -53, 36.19]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 16, joint_length = 5, trailing_length = 22,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }

    // Tuning slide goes here.
    if (global_in_place) {
      translate([10.1, -63, 15.69]) rotate([-90, 0, 0]) first_valve_slide();
    }

    translate([10.1, -53, 36.19]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 16, joint_length = 5, trailing_length = 6,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }
    translate([10.1, 4, 1.49]) rotate([0, 45, 0]) {
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

    translate([0.1, -16.0, 0]) straight_tube(3, bore=bore);
  }
}

module first_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10,
               trailing_length = 10, thickness = thickness, slide_thickness = 1,
               slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore=0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-10, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-20, 0, 0])
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10,
                   trailing_length = 10, thickness = 2, slide_thickness = 1,
                   slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore=0.413,
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
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 4,
                   trailing_length = 1, thickness = 2, slide_thickness = 1,
                   slide_gap_expansion = 0.1, thickness_compensation = 0.05,
                   bore = 0.413, disassembled = false, inner_only = false,
                   outer_only = true, shift = 0);
    }

    // Tuning slide goes here.
    if (global_in_place) {
      translate([0, 0, 28.1]) rotate([0, 180, -90]) second_valve_slide();
    }

    translate([0, -16, 28]) rotate([180, 0, 0]) {
      tuning_slide(leading_length = 10, slide_length = 10, joint_length = 4,
                   trailing_length = 1, thickness = 2, slide_thickness = 1,
                   slide_gap_expansion = 0.1, thickness_compensation = 0.05,
                   bore = 0.413, disassembled = false, inner_only = false,
                   outer_only = true, shift = 0);
    }

    translate([0, -16, 0]) straight_tube(3, bore=bore);
  }
}

module second_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10,
               trailing_length = 10, thickness = thickness, slide_thickness = 1,
               slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore = 0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-8, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 8,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-16, 0, 0]) {
    tuning_slide(leading_length = 10, slide_length = 10, joint_length = 10,
                 trailing_length = 10, thickness = thickness, slide_thickness = 1,
                 slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore = 0.413,
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
  brace_width = mmbore + (thickness * 2);

  // Brace
  difference() {
    translate([-10, -40.1 + (brace_width / 2), -40]) cube([20, brace_width, 16]);
    translate([0, 20.5, 0]) {
      translate([0, -10, 56]) rotate([90, 0, 0]) {
        translate([-9.9, -109, 36.19]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
        translate([10.1, -109, 36.19]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
      }
    }
  }

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -9.9, 56]) rotate([90, 0, 0]) {
    translate([0.1, 0, 0]) straight_tube(3, bore=bore);
    translate([-9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 135,
                    end_degrees = 180, reversed = true);
    }
    translate([-9.9, 0, 1.49]) rotate([0, -45, 0]) {
        translate([10, -10, 0]) rotate([0, 0, 90]) {
            curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                        radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                        thickness = thickness, start_degrees = 90,
                        end_degrees = 180, reversed = true);
        }
    }

    // 53mm to top of top hole  -- 109
    // 5.2 on y would be aligned with top of hole
    translate([-9.9, -109, 36.19]) rotate([-90, 0, 0]) {
        tuning_slide(leading_length = 0, slide_length = 68, joint_length = 5, trailing_length = 26,
                     bore=bore, disassembled = true, outer_only = true, shift = 0);
    }

    // Tuning slide goes here.
    if (global_in_place) {
      translate([10.1, -119, 15.69]) rotate([-90, 0, 0]) third_valve_slide();
    }

    translate([10.1, -109, 36.19]) rotate([-90, 0, 0]) {
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

    translate([10.1, -16, 1.49]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 45, reversed = true);
    }

    translate([0.1, -16, 0]) straight_tube(3, bore=bore);
  }
}

module third_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 10, slide_length = 68, joint_length = 10,
               trailing_length = 10, thickness = thickness, slide_thickness = 1,
               slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore = 0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([-10, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 270, reversed = true);
  }

  translate([-20, 0, 0])
      tuning_slide(leading_length = 10, slide_length = 68, joint_length = 10,
                   trailing_length = 10, thickness = 2, slide_thickness = 1,
                   slide_gap_expansion = 0.1, thickness_compensation = 0.05,
                   bore = 0.413, disassembled = false, inner_only = true,
                   outer_only = false, shift = 0);
}

module fourth_valve_tubing(bore = 0.413, thickness = 2) {
  // No measurements to work with, so guess.
  mmbore = inches_to_mm(bore);

  brace_width = mmbore + (thickness * 2);

  // Braces
  difference() {
    translate([0, -36 + (brace_width / 2), -60]) cube([100, brace_width, 16]);
      translate([0, -10, 56]) rotate([90, 0, 0]) {
        translate([0, -137.8, 11.5]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
        translate([99.9, -137.8, 11.5]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
      }
  }
  difference() {
    translate([0, -36 + (brace_width / 2), 9]) cube([100, brace_width, 16]);
      translate([0, -10, 56]) rotate([90, 0, 0]) {
        translate([0, -137.8, 11.5]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
        translate([99.9, -137.8, 11.5]) rotate([-90, 0, 0]) cylinder(100, brace_width/2, brace_width/2, $fn = 256);
      }
  }

  // 3mm inside the valve casing so it overlaps cleanly.
  translate([0, -10, 56]) rotate([90, 0, 0]) {

    // From the bottom valve port
    translate([0, -16, 0]) straight_tube(3, bore=bore);
    translate([0, -26, 1.5]) rotate([0, 0, -90]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true);
    }

    translate([0, -137.8, 11.5]) rotate([-90, 0, 0]) {
            tuning_slide(leading_length = 0, slide_length = 102, joint_length = 5,
                         trailing_length = 5, bore=bore, disassembled = false,
                         outer_only = true, shift = 0);
    }


    // Tuning slide goes here.
    if (global_in_place) {
      extend = true;
      translate([0, -116, 11.5]) rotate([-90, 0, 0]) translate([0, 0, extend ? -105 : 0]) fourth_valve_slide();
    }

    translate([99.9, -137.8, 11.5]) rotate([-90, 0, 0]) {
            tuning_slide(leading_length = 0, slide_length = 102, joint_length = 5,
                         trailing_length = 5, bore=bore, disassembled = false,
                         outer_only = true, shift = 0);
    }

    translate([99.9, -25.9, 11.5]) rotate([-90, 0, 0]) {
      straight_tube(15.9, bore = bore);
    }

    translate([89.9, -10, 11.5]) rotate([-90, 0, -90]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true);
    }

    // Estimated total length: 150mm + 275mm = 425mm
    translate([9.9, 0, 11.5]) rotate([0, 90, 0]) {
        straight_tube(80, bore = bore);
    }

    translate([9.9, 0, 1.5]) {
        curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                    radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                    thickness = thickness, start_degrees = 0,
                    end_degrees = 90, reversed = true);
    }
    straight_tube(3, bore=bore);
  }
}

module fourth_valve_slide(bore = 0.413, thickness = 2) {
  tuning_slide(leading_length = 5, slide_length = 102, joint_length = 5,
               trailing_length = 5, thickness = thickness, slide_thickness = 1,
               slide_gap_expansion = 0.1, thickness_compensation = 0.05, bore = 0.413,
               disassembled = false, inner_only = true, outer_only = false, shift = 0);

  mmbore = inches_to_mm(bore);

  translate([10, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 180,
                  end_degrees = 270, reversed = true);
  }

  translate([10, 0, -10]) rotate([0, 90, 0]) {
    straight_tube(80.1, bore = bore);
  }

  translate([90.1, 0, 0]) rotate([0, 90, 0]) {
      curved_tube(slices = 50, radius_1 = mmbore / 2 + thickness,
                  radius_2 = mmbore / 2 + thickness, bend_radius = 10,
                  thickness = thickness, start_degrees = 90,
                  end_degrees = 180, reversed = true);
  }

  translate([100.1, 0, 0])
      tuning_slide(leading_length = 5, slide_length = 102, joint_length = 5,
                   trailing_length = 5, thickness = 2, slide_thickness = 1,
                   slide_gap_expansion = 0.1, thickness_compensation = 0.05,
                   bore = 0.413, disassembled = false, inner_only = true,
                   outer_only = false, shift = 0);
}

module valve_block(bore = 0.413, thickness = 2.0, fourth_valve = true) {
  casing_height = 91.5;
  spacing = 25.4;

  translate([0, 0, 0]) piston_valve_casing(0.413, number = 1);
  translate([spacing, 0, 0]) piston_valve_casing(0.413, number = 2);
  translate([spacing * 2, 0, 0]) piston_valve_casing(0.413, number = 3);
  translate([spacing * 3, 0, 0]) piston_valve_casing(0.413, number = 4);

  difference() {
    union() {
      // Coupler for fastening receiver outer pipe.
      translate([-30, 0, 40.4]) rotate([0, 90, 0]) small_morse_receiver_coupler(bore = bore);

      translate([9, 0, 56]) rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);
      translate([9 + (spacing), 0, 40]) rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);
      translate([9 + (spacing * 2), 0, 56])
          rotate([0, 90, 0]) straight_tube(spacing - 17, 3.0, bore);

      // Valve mount.
      translate([17.5, -23, 71.2]) cube([40, 23.5, 5]);

      // Coupler to bell short straight pipe.
      translate([323.5, 28.05, -7.72]) rotate([0, -90, 0]) {
        difference() {
          // length 115
          bell_short_straight_pipe(bore = bore, thickness = thickness, coupler_mode = true);
          translate([0, -50, 110]) cube([100, 100, 115]);
        }
        translate([47.7, -28, 236]) straight_tube(3, bore = mm_to_inches(12 + (2 * thickness) + 0.2), thickness = thickness);
      }
    }

    // Valve interior cutouts (approximate, not including flat edge).
    translate([0, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing * 2, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);
    translate([spacing * 3, 0, 6]) cylinder(casing_height - 16, 13, 13, $fn=256);

    // Valve mount hole
    translate([38.5, -19.275, 60]) rotate([0, 0, 90]) cylinder(30, 2, 2, $fn=256);
  }
}

module valve_parts(bore = 0.413, enable_caps = true) {
  translate([0, 40, 0]) piston_valve(bore, number = 1);
  translate([40, 40, 0]) piston_valve(bore, number = 2);
  translate([80, 40, 0]) piston_valve(bore, number = 3);
  translate([120, 40, 0]) piston_valve(bore, number = 4);

  if (enable_caps) {
    translate([0, -60, 0]) piston_valve_cap();
    translate([40, -60, 0]) piston_valve_cap();
    translate([80, -60, 0]) piston_valve_cap();
    translate([120, -60, 0]) piston_valve_cap();

    translate([0, -100, 0]) piston_valve_cap();
    translate([40, -100, 0]) piston_valve_cap();
    translate([80, -100, 0]) piston_valve_cap();
    translate([120, -100, 0]) piston_valve_cap();
  }
}


bell_main_segment_inner_radius = function(z) (15.57032 + (136.93058/(1 + (z/23.73906)))) / 2;
bell_main_segment_slope = function(z) -406325468068.5 / (((50000 * z) + 1186953)^2);

module bell_main_segment(bore=0.413, start_slice = 0, stop_slice = undef, height = 337,
                         thickness = 2.0, coupler_mode = false,
                         emit_first_part = true, emit_second_part = true,
                         emit_coupler = true) {
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

                    cylinder(sliceHeight, bell_main_segment_inner_radius(zOffset) + widthAtBottom +
                             (coupler_mode ? widthAtBottom + .1 : 0),
                             bell_main_segment_inner_radius(nextZOffset) + widthAtTop +
                             (coupler_mode ? widthAtTop + .1 : 0), $fn = 256);
                    cylinder(sliceHeight, bell_main_segment_inner_radius(zOffset) +
                             (coupler_mode ? widthAtBottom : 0),
                             bell_main_segment_inner_radius(nextZOffset) +
                             (coupler_mode ? widthAtTop : 0), $fn = 256);
                }
            }
        }
    }
    if (!coupler_mode) {
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
}

module bell_big_curve(bore=0.413, thickness = 2.0, coupler_mode = 0) {
    // Length of the outside of the tube is 2 * pi * (bend_radius + radius_1).

    bend_radius = 76;

    // At 337mm from end of bell, interior radius is 12.29mm.  Add thickness.
    // At other end of curve, 19mm diameter, 9.5mm radius.
    number_of_slices = (high_quality ? 600 : 100);
    curved_tube(slices = number_of_slices,
                radius_1 = 12.29 + thickness + ((coupler_mode > 0) ? thickness + 0.1 : 0),
                radius_2 = 9.5 + thickness + ((coupler_mode > 0) ? thickness + 0.1 : 0),
                bend_radius = bend_radius,
                thickness = thickness + (coupler_mode ? 0.2 : 0),
                enable_brace = (coupler_mode == 0),
                emit_from_slice = ((coupler_mode == 1) ? 0 : ((coupler_mode == 2) ? (number_of_slices * .98) : undef)),
                emit_to_slice = ((coupler_mode == 1) ? (number_of_slices / 50) : ((coupler_mode == 2) ? number_of_slices : undef)));
}

module bell_small_curve_with_couplers(bore=0.413, thickness = 2.0, bell_length = 337) {
  translate([99.85, -14, 121]) rotate([0, 180, 15]) {
    bell_small_curve(bore = bore, thickness = thickness);
    // Large side
    bell_small_curve(bore = bore, thickness = thickness, coupler_mode = 1);
    // Small side
    bell_small_curve(bore = bore, thickness = thickness, coupler_mode = 2);
  }

  difference() {
    union() {
      bell_long_straight_pipe(bore = bore, thickness = thickness, coupler_mode = true);
      bell_short_straight_pipe(bore = bore, thickness = thickness, coupler_mode = true);
    }
    translate([0, -100, 131]) cube([200, 200, bell_length]);
  }
}

module bell_small_curve(bore=0.413, thickness = 2.0, coupler_mode = 0) {
    // Length of the outside of the tube is 2 * pi * (bend_radius + radius_1).

    // At opposite ends, 17mm and 14mm approximate inner diameter,
    // 8.5mm and 7mm inner radius.
    //
    // Original instrument is 130mm between the outer sides of the tubes,
    // and 102mm between the inner sides of the tubes, as measured near the
    // bell end, so the diameter of the bend is halfway between, or 116mm.
    // The radius is therefore about 58mm.

    number_of_slices = (high_quality ? 600 : 100);

    difference() {
      union() {
        curved_tube(slices = number_of_slices,
                    radius_1 = 8.5 + thickness + ((coupler_mode > 0) ? thickness + 0.1 : 0),
                    radius_2 = 7 + thickness + ((coupler_mode > 0) ? thickness + 0.1 : 0),
                    bend_radius = 54, thickness = thickness + ((coupler_mode > 0) ? 0.2 : 0),
                    emit_from_slice = ((coupler_mode == 1) ? 0 : ((coupler_mode == 2) ? (number_of_slices * .96) : undef)),
                    emit_to_slice = ((coupler_mode == 1) ? (number_of_slices / 25) : ((coupler_mode == 2) ? number_of_slices : undef)));

        // Spit valve hole rim
        if (!coupler_mode) {
          translate([-59, 0, 23.5]) rotate([180, 111, 0]) cylinder(3.5, 2.75, 2.75, $fn = 256);
        }
      }
      // Spit valve hole
      if (!coupler_mode) {
        translate([-59, 0, 23.5]) rotate([180, 111, 0]) translate([0, 0, -2]) cylinder(20, 1.5, 1.5, $fn = 256);
      }
    }

    if (!coupler_mode) {
      translate([-65.2, 0, 15]) rotate([0, -16, 180]) translate([-3, 0, 0]) {
        spit_valve(enable_mount = true, enable_flap = global_in_place);
      }
    }
}

module curved_tube(bore=0.413, thickness = 2.0, radius_1 = 10,
                   radius_2 = 20, bend_radius = 40, thickness = 2,
                   slices = 100, enable_brace = false, start_degrees = 0,
                   end_degrees = 180, emit_from_slice = undef, emit_to_slice = undef,
                   reversed = false) {
    midwidth = radius_1 - (radius_1-radius_2)/2;
    difference()
    {
        union() {
            skin([for(i=[0:slices], $fn = 256)
                for (should_emit = ((emit_from_slice == undef) || (i >= emit_from_slice)) &&
                              ((emit_to_slice == undef) || (i <= emit_to_slice)))
                  transform(rotation([0, start_degrees + ((end_degrees - start_degrees) / slices * i), 0]) *
                            translation([-bend_radius, 0, 0]),
                            (should_emit) ? circle(radius_1 - (radius_1 - radius_2) / slices * i, $n = 256) : circle(0))]);
            if (enable_brace) {
                translate([-25, -5, bend_radius - midwidth - 20]) cube([30, 10, 20 + midwidth]);
                translate([-20, -21.6, bend_radius - midwidth - 20]) cube([25, 21.6, 20 + midwidth]);
            }
        }

        for(radius_1 = radius_1-thickness, radius_2 = radius_2-thickness) {
            skin([for(i=[0:slices], $fn = 256)
                for (should_emit = ((emit_from_slice == undef) || (i >= emit_from_slice)) &&
                                ((emit_to_slice == undef) || (i < emit_to_slice)))
                  transform(rotation([0, start_degrees + ((end_degrees - start_degrees) / slices * i), 0]) *
                            translation([-bend_radius, 0, 0]),
                            circle(radius_1 - (radius_1 - radius_2) / slices * i), $fn = 256)]);
        }

        /* Clean up the interior of the ends */
        rotate([0, start_degrees, 0]) translate([-bend_radius, 0, -0.01]) cylinder(0.02, radius_1, radius_1);
        rotate([0, end_degrees, 0]) translate([-bend_radius, 0, -0.01]) cylinder(0.02, radius_2, radius_2);

        if (enable_brace) {
          translate([-10, 20, bend_radius - midwidth - 10]) {
              rotate([90, 0, 0]) cylinder(60, 2, 2, $fn = 256);
          }
        }
    }
}

module bell_big_curve_with_couplers(bore=0.413, thickness = 2.0, bell_length = 337) {
    bell_main_segment(bore = bore, height = bell_length, thickness = thickness, start_slice = 327, coupler_mode = true);
    translate([76, 0, bell_length]) bell_big_curve(bore = bore, thickness = thickness);
    translate([76, 0, bell_length]) bell_big_curve(bore = bore, thickness = thickness, coupler_mode = 1);
    translate([76, 0, bell_length]) bell_big_curve(bore = bore, thickness = thickness, coupler_mode = 2);
    difference() {
      bell_long_straight_pipe(bore, thickness, coupler_mode = true);
      translate([114, -30, 0]) cube([60, 60, bell_length - 10]);
    }
}

module bell_long_straight_pipe(bore=0.413, thickness = 2.0, coupler_mode = false) {
    // Experimentally, 0.2 is too much gap here, so switched to 0.1.  That was also
    // way too big, so reduced to 0.02.
    id_2 = 19 + (coupler_mode ? ((2 * thickness) + 0.02) : 0);
    id_2_inches = mm_to_inches(id_2);
    id_1 = 17 + (coupler_mode ? ((2 * thickness) + 0.02) : 0);
    id_1_inches = mm_to_inches(id_1);

    translate([152, 0, 121]) sloped_tube(216, thickness = thickness, bore_1 = id_1_inches,
                                         bore_2 = id_2_inches);
}

module bell(bore=0.413, thickness = 2.0) {
    bell_length = 337;

    bell_main_segment(bore = bore, height = bell_length, thickness = thickness,
                      emit_first_part = true, emit_second_part = global_in_place,
                      emit_coupler = global_in_place);
    if (!global_in_place) {
      translate([0, 0, 0]) {
        bell_main_segment(bore = bore, height = bell_length, thickness = thickness,
                          emit_first_part = false, emit_second_part = true,
                          emit_coupler = true);
      }
    }

    // Big curve with couplers
    translate([global_in_place ? 0 : -80,
               global_in_place ? 0 : 100,
               global_in_place ? 0 : 10 - bell_length]) {
        bell_big_curve_with_couplers(bore = bore, thickness = thickness, bell_length = bell_length);
    }

    translate([global_in_place ? 0 : -52,
               global_in_place ? 0 : 70,
               global_in_place ? 0 : -121]) {
      bell_long_straight_pipe(bore = bore, thickness = thickness);
    }

    mmbore = inches_to_mm(bore);

    if (global_in_place) {
      bell_small_curve_with_couplers(bore = bore, thickness = thickness,
                                     bell_length = bell_length);
    } else {
      translate([0, -100, 0]) rotate([0, 0, 30]) translate([0, 0, 10])
        rotate([0, -180, -15]) translate([-99.85, 14, -121])
          bell_small_curve_with_couplers(bore = bore, thickness = thickness,
                                         bell_length = bell_length);

    }

    translate([global_in_place ? 0 : -152,
               global_in_place ? 0 : 80,
               global_in_place ? 0 : -121]) {
      bell_short_straight_pipe(bore = bore, thickness = thickness);
    }

// 400mm end of bell to outer edge of first curve.
// 372mm end of curve to end of curve (outer).

// 376 mm straight in is inside edge of curve.
// First curved part is ~172mm from outside at top to outside at bottom where it starts to curve.
// First curved part is ~135mm from inside to inside where it starts to curve.
// Start of curve (as measured on the inner side of curve is about 336mm to end of bell.
// Midpoint of curve is 23mm.
//
// From end of curve back to valves, slope is conical (linearly).  As best I can tell, the
// first curve is also roughly linear, to within 0.5mm after the entire length of the curve,
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

module bell_short_straight_pipe(bore=0.413, thickness = 2.0, coupler_mode = false) {
    id_3 = 14 + (coupler_mode ? ((2 * thickness) + 0.02) : 0);
    id_3_inches = mm_to_inches(id_3);
    id_4 = 12 + (coupler_mode ? ((2 * thickness) + 0.02) : 0);
    id_4_inches = mm_to_inches(id_4);

    translate([47.7, -28, 121]) sloped_tube(115, thickness = 2, bore_1 = id_3_inches,
                                         bore_2 = id_4_inches);
}

// First valve slide: Out 22mm at 20 degrees, curve down.  53mm from top of top hole to
//                    tuning slide joint (21mm usable).  15mm interior.  10mm overlap.
//                    12mm from overlap to middle of curve.  20mm between outside of one
//                    tube and outside of next tube (e.g. left to left or right to right).
//                    10mm joint.  21mm slide segment.  Curve back to valve.
// Second valve slide: 9mm inner slide, 14mm slide joint to casing, 7mm overlap,
//                     ~12mm to middle of arc, or a little less because of narrower gap.
// Third valve slide: Same as first, but 28mm between slides, 104mm from top of top hole
//                    to slide gap on long side, 69mm interior slide length.

module spit_valve(enable_flap = true, enable_mount = true) {
  // Designed for a 1/4" x 7/8" stretch spring (Amazon ASIN B097R78LN2).
  // Also used Amazon ASIN B0DCGJ65QC for valve springs, but they're too strong.
  // Look for something else.

  if (enable_flap) {
    translate([1, 0, 10]) rotate([0, 90, 0]) {
      difference() {
        cylinder(4.5, 5, 5, $fn = 256);
        cylinder(3.5, 4.5, 4.5, $fn = 256);
      }
      difference() {
        translate([0, 0, -96]) rotate([90, -90, 0]) translate([0, 0, -2]) rotate_extrude(angle = 45, $fn = 256) {
          translate([100, 0, 0]) square([6, 4]);
        }
        translate([-36, 15, 1]) rotate([90, 0, 0]) cylinder(30, 1.2, 1.2, $fn = 256);
      }
      // Hook
      translate([-15, -2, -1.5]) {
        cube([4, 4, 6]);
        cube([7, 4, 2]);
      }
    }
  }

  if (enable_mount) {
    translate([1, 0, 10]) rotate([0, 90, 0]) {
      difference() {
        union() {
          translate([-33.5, -5, -13.5]) rotate([0, -31, 0]) translate([0, 0, -2]) {
            difference() {
              translate([0, -3, -2]) cube([10, 16, 21]);
              translate([-0.1, 2.8, 0]) cube([10.2, 4.4, 19]);
              translate([-0.1, 1.5, 0]) cube([10.2, 7, 11]);

              // Avoid clogging the tube.
              rotate([0, 90, 0]) translate([9, 5, -5]) rotate([0, -3, 0]) translate([1, 0, -15]) cylinder(50, 10, 10, $fn = 256);
              translate([0, 0, 19]) rotate([0, 10, 0]) translate([-5, -5, 0]) cube([20, 20, 30]);
            }
          }
          // Hook block
          translate([-38.5, -5, -13.5]) rotate([0, -31, 0]) translate([0, 0, -2]) {
            cube([11.5, 10, 3]);
            translate([0, 3, 0]) cube([4, 4, 6]);
            translate([-3, 3, 4]) cube([7, 4, 2]);
          }
        }
        translate([-36, 15, 1]) rotate([90, 0, 0]) cylinder(30, 1.2, 1.2, $fn = 256);
      }
    }
  }
}

if (global_build_group == 0) {
    // Build instrument in place
    bell();
    translate([86.3, -17.6, 323.5]) rotate([0, -90, 15]) rotate([0, 0, 180]) valve_block();
    translate([47.3, -27.6, 449]) rotate([0, 180, -165]) small_morse_receiver(disassembled = false);
} else if (global_build_group == 1) {
    // Group 1: Valve casing.
    translate([100, 0, casing_height]) rotate([0, 180, 0]) valve_block();
} else if (global_build_group == 2) {
    valve_parts(enable_caps = false);
} else if (global_build_group == 3) {
    // Group 2: Bell parts.
    bell();
} else if (global_build_group == 4) {
    // Output the spit valve lever.  This is a small part that requires somewhat
    // intricate support, and probably has to use dissolvable support as a result,
    // so output it as its own file.
    translate([0, 45, 8]) rotate([90, 0, 0]) spit_valve(enable_mount = false, enable_flap = true);
} else if (global_build_group == 5) {
    // Tuning slides - use ONLY *external* support (manual paint) or dissolvable
    // supports (or both).

    translate([50, 0, 20]) rotate([180, 0, 0]) first_valve_slide();
    translate([-50, 0, 20]) rotate([180, 0, 0]) second_valve_slide();
    translate([-50, 50, 78]) rotate([180, 0, 0]) third_valve_slide();
    translate([-50, -50, 107]) rotate([180, 0, 0]) fourth_valve_slide();
} else if (global_build_group == 6) {
    // Mouthpiece receiver - use ONLY *external* support (manual paint) or dissolvable
    // supports (or both).
    small_morse_receiver(disassembled = true);
} else if (global_build_group == 7) {
    piston_valve_casing(bore=0.413, number=1, valve_thread_pitch = 2, for_measurement = true);
}
