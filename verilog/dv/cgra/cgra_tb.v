// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`include "caravel_netlists.v"
`include "uprj_netlists.v"
`include "spiflash.v"

module cgra_tb;
	reg clock;
	reg io_clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;
	wire [1:0] message = mprj_io[37:36];

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.
    localparam CLK_PERIOD = 16;
	always #(CLK_PERIOD/2) io_clock <= (io_clock === 1'b0);
	always #(CLK_PERIOD/2) clock <= (clock === 1'b0);

	initial begin
		io_clock = 1;
		clock = 0;
	end

	integer c;
	initial begin
		c = 0;
		$dumpfile("cgra.vcd");
		$dumpvars(0, cgra_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (2000) begin
			repeat (1000) @(posedge clock);
			c = c + 1;
			$display(" - %0d k cycles", c);
		end
		$display("%c[1;31m",27);
	
		$display ("Monitor: Timeout, Test Mega-Project WB Port (RTL) Failed");

		$display("%c[0m",27);
		$finish;
	end

	integer input_pgm_file;
    integer conv_3_3_bs_file;
    integer conv_3_3_bs_out_file;
	initial begin
		input_pgm_file = $fopen("./data/input.pgm.raw", "r");
        conv_3_3_bs_file = $fopen("./data/conv_3_3.bs.out", "w");
        conv_3_3_bs_out_file = $fopen("./data/conv_3_3.bs.out.valid", "w");
	end

	integer i, j;
	reg [15:0] input_pgm_in;

	reg [15:0] glb2io_16;
	reg        glb2io_1;
	reg        io_reset;
	// connect FPGA data ports
	assign mprj_io[15:0] = glb2io_16;
	assign mprj_io[16]   = glb2io_1;
	// connect FPGA clock/reset
	assign mprj_io[34] = io_clock;
	assign mprj_io[35] = io_reset;

	// Emulate FPGA Behavior
	initial begin
        // initialization
		glb2io_16 = 16'd0;
        glb2io_1  = 1'b0;
		io_reset = 1'b1;

		// internal CGRA config start
		wait(message == 2'd1); 
		$display("[Monitor]: Configuration Start");
		io_reset = 1'b0;

		// internal CGRA config end
		wait(message == 2'd2); 
		$display("[Monitor]: Configuration End");

		// wait 1k cycles to make sure sel changes to IO clock/reset
		$display("[Monitor]: Wait 1k cycles to make sure sel changes to IO clock/reset");
		@(posedge io_clock);
		#(CLK_PERIOD*1000);

		// Input feeding start
		$display("[Monitor]: Start feeding inputs to CGRA");
        @(negedge io_clock) glb2io_1 = 1'd1;
        @(negedge io_clock) glb2io_1 = 1'd0;
		for (i=0; i<4096; i=i+1) begin
            input_pgm_in = 0;
            for (j=0; j<2; j=j+1) begin
                input_pgm_in |= $fgetc(input_pgm_file) << (8 * j);
            end
            glb2io_16 = input_pgm_in;
            #1;
            for (j = 0; j < 2; j=j+1) begin
                $fwrite(conv_3_3_bs_file, "%c", (mprj_io[32:17] >> (8 * j)) & 8'hFF);
            end
            for (j = 0; j < 1; j=j+1) begin
                $fwrite(conv_3_3_bs_out_file, "%c", (mprj_io[33] >> (8 * j)) & 8'hFF);
            end
            @(negedge io_clock);
        end
        $fclose(input_pgm_file);
        $fclose(conv_3_3_bs_file);
        $fclose(conv_3_3_bs_out_file);

		$display("[Monitor]: ALL outputs catched, Simulation Finish, please check outputs");
        #(CLK_PERIOD*3);
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	//always @(mprj_io) begin
	//	#1 $display("MPRJ-IO in = %b ", mprj_io); // [16:1]);
    //    #1 $display("MPRJ-IO out = %b ", mprj_io); // [33:18]);
	//end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("cgra.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
