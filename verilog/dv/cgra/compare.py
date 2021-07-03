import os
import sys

def compare():
    output_filename = "./data/conv_3_3.bs.out"
    gold_filename = "./data/gold.pgm.raw"
    valid_filename = "./data/conv_3_3.bs.out.valid"
    has_valid = True
    pixel_size = 2 # 1 if not pgm, 2 if pgm
    _input_size = 1
    compare_size = os.path.getsize(gold_filename)
    with open(output_filename, "rb") as design_f:
        with open(gold_filename, "rb") as halide_f:
            with open(valid_filename, "rb") as onebit_f:
                pos = 0
                skipped_pos = 0
                while True:
                    design_byte = design_f.read(1)
                    if pos % (pixel_size * _input_size) == 0:
                        onebit_byte = onebit_f.read(1)
                    if not design_byte:
                        break
                    pos += 1
                    design_byte = ord(design_byte)
                    if not isinstance(onebit_byte, int):
                        onebit_byte = ord(onebit_byte)
                    onebit_byte = onebit_byte if has_valid else 1
                    if onebit_byte != 1:
                        skipped_pos += 1
                        continue
                    halide_byte = halide_f.read(1)
                    if len(halide_byte) == 0:
                        break
                    halide_byte = ord(halide_byte)
                    if design_byte != halide_byte:
                        print("design:", design_byte, file=sys.stderr, end=" ")
                        print("halide:", halide_byte, file=sys.stderr)
                        raise Exception("Error at pos " + str(pos), "real pos",
                                        pos - skipped_pos)

    compared_size = pos - skipped_pos
    if compared_size != compare_size:
        raise Exception("Expected to produce " + str(compare_size) +
                        " valid bytes, got " + str(compared_size))
    print("PASS: compared with", pos - skipped_pos, "bytes")
    print("Skipped", skipped_pos, "bytes")

if __name__ == "__main__":
    # do comparison
    compare()
