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
/*
 *-------------------------------------------------------------
 *
 * user_proj_cgra
 * 
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter WISHBONE_BASE_ADDR = 32'h30000000
)(
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif
    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,
    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,
    // IRQ
    output [2:0] irq
);

// ==============================================================================
// Wishbone control
// ==============================================================================
    wire [31:0] CGRA_read_config_data;
    wire [31:0] CGRA_config_config_addr;
	wire [31:0] CGRA_config_config_data;
	wire        CGRA_config_read;
	wire        CGRA_config_write;
    wire  [3:0] CGRA_stall;
    wire  [1:0] message;
    // clock/reset mux
    wire sel = la_data_in[96];
    wire ckmux_clk;
    wire ckmux_rst;
    ckmux ckmux_u0 (
      .select  ( sel       )
    , .clk0    ( wb_clk_i  )
    , .clk1    ( io_in[34] )
    , .out_clk ( ckmux_clk )
    );
    assign ckmux_rst = (sel) ? io_in[35] : wb_rst_i;

    wishbone_ctl #(
        .WISHBONE_BASE_ADDR(WISHBONE_BASE_ADDR)
    ) wbs_ctl_u0 (
    // wishbone input
      .wb_clk_i  ( ckmux_clk  )
    , .wb_rst_i  ( ckmux_rst  )
    , .wbs_stb_i ( wbs_stb_i )
    , .wbs_cyc_i ( wbs_cyc_i )
    , .wbs_we_i  ( wbs_we_i  )
    , .wbs_sel_i ( wbs_sel_i )
    , .wbs_dat_i ( wbs_dat_i )
    , .wbs_adr_i ( wbs_adr_i )
    // wishbone output
    , .wbs_ack_o ( wbs_ack_o )
    , .wbs_dat_o ( wbs_dat_o )
    // input from CGRA
    , .CGRA_read_config_data ( CGRA_read_config_data )
    // output
    , .CGRA_config_config_addr( CGRA_config_config_addr )
	, .CGRA_config_config_data( CGRA_config_config_data )
	, .CGRA_config_read       ( CGRA_config_read        )
	, .CGRA_config_write      ( CGRA_config_write       )
    , .CGRA_stall             ( CGRA_stall              )
    , .message                ( message                 )
);

assign io_out[36] = message[0];
assign io_out[37] = message[1];
assign io_out[34] = 1'b0;
assign io_out[35] = 1'b0; 


/* Manually add buffers, these buffers are used to avoid hold-time violation in final array level PD */
// The power pins are essential for simulation
localparam P = 8;
wire [31:0] POHAN_BUF_CGRA_config_config_data [0:P-1];
wire [3:0]  POHAN_BUF_CGRA_stall [0:P-1];
genvar i, j, k;
generate
    // stage 0
    for (j=0; j<32; j=j+1) begin : BUF_STAGE_0_CONFIG_BIT
        sky130_fd_sc_hd__buf_12 POHAN_BUF_CONFIG_DATA (
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
        `endif
            .A(CGRA_config_config_data[j]), 
            .X(POHAN_BUF_CGRA_config_config_data[0][j])
        );
    end
    for (k=0; k<4; k=k+1) begin : BUF_STAGE_0_STALL_BIT
        sky130_fd_sc_hd__buf_12 POHAN_BUF_STALL (
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
        `endif
            .A(CGRA_stall[k]),
            .X(POHAN_BUF_CGRA_stall[0][k])
        );
    end
    // stage 1~(P-1)
    for (i=0; i<(P-1); i=i+1) begin : BUF_STAGE
        for (j=0; j<32; j=j+1) begin : CONFIG_BIT
            sky130_fd_sc_hd__buf_12 POHAN_BUF_CONFIG_DATA (
            `ifdef USE_POWER_PINS
                .VPWR(vccd1),
                .VGND(vssd1),
            `endif
                .A(POHAN_BUF_CGRA_config_config_data[i][j]),
                .X(POHAN_BUF_CGRA_config_config_data[i+1][j])
            );
        end
        for (k=0; k<4; k=k+1) begin : STALL_BIT
            sky130_fd_sc_hd__buf_12 POHAN_BUF_STALL (
            `ifdef USE_POWER_PINS
                .VPWR(vccd1),
                .VGND(vssd1),
            `endif
                .A(POHAN_BUF_CGRA_stall[i][k]),
                .X(POHAN_BUF_CGRA_stall[i+1][k])
            );
        end
    end
endgenerate


// ==============================================================================
// IO Logic
// ==============================================================================

    wire [15:0] glb2io_16_X00_Y00 = io_in[15:0];
    wire [15:0] glb2io_16_X01_Y00 = io_in[32:17];
    wire        glb2io_1_X00_Y00  = io_in[16];
    wire        glb2io_1_X01_Y00  = io_in[33];
    wire [15:0] io2glb_16_X00_Y00;
    wire [15:0] io2glb_16_X01_Y00;
    wire        io2glb_1_X00_Y00;
    wire        io2glb_1_X01_Y00;

    assign io_out[15:0]  = io2glb_16_X00_Y00;
    assign io_out[32:17] = io2glb_16_X01_Y00;
    assign io_out[16]    = io2glb_1_X00_Y00;
    assign io_out[33]    = io2glb_1_X01_Y00;

    Interconnect Interconnect_inst0 (
        // common
        .clk                  ( ckmux_clk             ),
        .reset                ( ckmux_rst             ),
        .stall                ( POHAN_BUF_CGRA_stall[P-1]            ),
        .read_config_data     ( CGRA_read_config_data ),
        // configuration
        .config_0_config_addr ( CGRA_config_config_addr ), // broadcast config
        .config_0_config_data ( POHAN_BUF_CGRA_config_config_data[P-1] ), // broadcast config
        .config_0_read        ( CGRA_config_read        ), // broadcast config
        .config_0_write       ( CGRA_config_write       ), // broadcast config
        .config_1_config_addr ( CGRA_config_config_addr ), // broadcast config
        .config_1_config_data ( POHAN_BUF_CGRA_config_config_data[P-1] ), // broadcast config
        .config_1_read        ( CGRA_config_read        ), // broadcast config
        .config_1_write       ( CGRA_config_write       ), // broadcast config
        .config_2_config_addr ( CGRA_config_config_addr ), // broadcast config
        .config_2_config_data ( POHAN_BUF_CGRA_config_config_data[P-1] ), // broadcast config
        .config_2_read        ( CGRA_config_read        ), // broadcast config
        .config_2_write       ( CGRA_config_write       ), // broadcast config
        .config_3_config_addr ( CGRA_config_config_addr ), // broadcast config
        .config_3_config_data ( POHAN_BUF_CGRA_config_config_data[P-1] ), // broadcast config
        .config_3_read        ( CGRA_config_read        ), // broadcast config
        .config_3_write       ( CGRA_config_write       ), // broadcast config
        // inputs
        .glb2io_16_X00_Y00    ( glb2io_16_X00_Y00 ),
        .glb2io_16_X01_Y00    ( glb2io_16_X01_Y00 ),
        .glb2io_1_X00_Y00     ( glb2io_1_X00_Y00  ),
        .glb2io_1_X01_Y00     ( glb2io_1_X01_Y00  ),
        // outputs
        .io2glb_16_X00_Y00    ( io2glb_16_X00_Y00 ),
        .io2glb_16_X01_Y00    ( io2glb_16_X01_Y00 ),
        .io2glb_1_X00_Y00     ( io2glb_1_X00_Y00  ),
        .io2glb_1_X01_Y00     ( io2glb_1_X01_Y00  ),
        // not used
        .glb2io_16_X02_Y00    ( 16'd0 ), // not used
        .glb2io_16_X03_Y00    ( 16'd0 ), // not used
        .glb2io_1_X02_Y00     ( 1'b0  ), // not used
        .glb2io_1_X03_Y00     ( 1'b0  ), // not used
        .io2glb_16_X02_Y00    (       ), // not used
        .io2glb_16_X03_Y00    (       ), // not used
        .io2glb_1_X02_Y00     (       ), // not used
        .io2glb_1_X03_Y00     (       )  // not used
    );

    // IO direction
    // assign io_oeb[16:0]  = {17{1'b1}};
    // assign io_oeb[33:17] = {17{1'b0}};
    // assign io_oeb[34]  = 1'b1; // io_clk
    // assign io_oeb[35]  = 1'b1; // io_reset
    // assign io_oeb[36]  = 1'b0; // config done
    // assign io_oeb[37]  = 1'b0; // test
    assign io_oeb = la_data_in[37:0];

    // Unused
    assign irq = 3'b000;
    assign la_data_out = 128'd0;

endmodule

